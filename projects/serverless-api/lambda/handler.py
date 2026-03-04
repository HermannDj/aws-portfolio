"""
Lambda handler for the Serverless API project.

Supports CRUD operations on a DynamoDB table via API Gateway proxy integration.

Routes:
  GET    /items        – list all items (scan)
  POST   /items        – create an item
  GET    /items/{id}   – get a single item
  PUT    /items/{id}   – update an item
  DELETE /items/{id}   – delete an item
"""

import json
import logging
import os
import uuid
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    level=getattr(logging, LOG_LEVEL, logging.INFO),
)
logger = logging.getLogger(__name__)

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)  # noqa: B023


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
class DecimalEncoder(json.JSONEncoder):
    """Convert Decimal values returned by DynamoDB to int/float."""

    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super().default(obj)


def _response(status_code: int, body: object) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "X-Request-Id": str(uuid.uuid4()),
        },
        "body": json.dumps(body, cls=DecimalEncoder),
    }


def _parse_body(event: dict) -> dict:
    raw = event.get("body") or "{}"
    if isinstance(raw, str):
        return json.loads(raw)
    return raw


# ---------------------------------------------------------------------------
# Route handlers
# ---------------------------------------------------------------------------
def list_items() -> dict:
    logger.info("list_items")
    result = table.scan()
    return _response(200, {"items": result.get("Items", [])})


def create_item(body: dict) -> dict:
    item_id = str(uuid.uuid4())
    item = {"id": item_id, **body}
    table.put_item(Item=item)
    logger.info("create_item id=%s", item_id)
    return _response(201, {"item": item})


def get_item(item_id: str) -> dict:
    result = table.get_item(Key={"id": item_id})
    item = result.get("Item")
    if not item:
        logger.warning("get_item id=%s not found", item_id)
        return _response(404, {"message": f"Item {item_id!r} not found."})
    logger.info("get_item id=%s", item_id)
    return _response(200, {"item": item})


def update_item(item_id: str, body: dict) -> dict:
    if not body:
        return _response(400, {"message": "Request body must not be empty."})

    # Build a dynamic UpdateExpression from the supplied fields
    expr_names: dict = {}
    expr_values: dict = {}
    set_parts: list = []

    for idx, (key, value) in enumerate(body.items()):
        if key == "id":
            continue  # never overwrite the partition key
        placeholder = f"#attr{idx}"
        value_key = f":val{idx}"
        expr_names[placeholder] = key
        expr_values[value_key] = value
        set_parts.append(f"{placeholder} = {value_key}")

    if not set_parts:
        return _response(400, {"message": "No updatable fields provided."})

    update_expr = "SET " + ", ".join(set_parts)

    result = table.update_item(
        Key={"id": item_id},
        UpdateExpression=update_expr,
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
        ConditionExpression="attribute_exists(id)",
        ReturnValues="ALL_NEW",
    )
    logger.info("update_item id=%s", item_id)
    return _response(200, {"item": result.get("Attributes", {})})


def delete_item(item_id: str) -> dict:
    table.delete_item(
        Key={"id": item_id},
        ConditionExpression="attribute_exists(id)",
    )
    logger.info("delete_item id=%s", item_id)
    return _response(200, {"message": f"Item {item_id!r} deleted."})


# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------
def lambda_handler(event: dict, context) -> dict:  # noqa: ANN001
    logger.debug("event=%s", json.dumps(event))

    http_method = event.get("httpMethod", "")
    path_params = event.get("pathParameters") or {}
    item_id = path_params.get("id")

    try:
        if http_method == "GET" and not item_id:
            return list_items()

        if http_method == "POST":
            return create_item(_parse_body(event))

        if http_method == "GET" and item_id:
            return get_item(item_id)

        if http_method == "PUT" and item_id:
            return update_item(item_id, _parse_body(event))

        if http_method == "DELETE" and item_id:
            return delete_item(item_id)

        return _response(405, {"message": f"Method {http_method!r} not allowed."})

    except table.meta.client.exceptions.ConditionalCheckFailedException:
        return _response(404, {"message": f"Item {item_id!r} not found."})
    except json.JSONDecodeError as exc:
        logger.error("JSON decode error: %s", exc)
        return _response(400, {"message": "Invalid JSON in request body."})
    except Exception as exc:  # pylint: disable=broad-except
        logger.exception("Unhandled exception: %s", exc)
        return _response(500, {"message": "Internal server error."})
