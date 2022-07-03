#https://thecodinginterface.com/blog/aws-sam-serverless-rest-api-with-flask/
import os
from datetime import datetime
import uuid
import json
import boto3
from boto3.dynamodb.conditions import Key
import time
from flask import request, jsonify
from flask_lambda import FlaskLambda

response = {'data': {}, 'message': ""}
DEFAULT_DATE = '1999-01-01'

# EXEC_ENV = os.environ['EXEC_ENV']
# REGION = os.environ['REGION_NAME']
# TABLE_NAME = os.environ['TABLE_NAME']
# print(os.environ)
S3_BUCKET_NAME = os.environ['BUCKET_NAME']
S3_PREFIX = 'chumps'

ssm = boto3.client('ssm')
s3_client = boto3.client("s3")

app = FlaskLambda(__name__)

# if EXEC_ENV == 'local':
#     dynamodb = boto3.resource('dynamodb', endpoint_url='http://dynamodb:8000')
# else:
#     dynamodb = boto3.resource('dynamodb', region_name=REGION)


# def db_table(table_name=TABLE_NAME):
#     return dynamodb.Table(table_name)

def _get_ssm_param(key):
    return ssm.get_parameter(Name=key, WithDecryption=True)['Parameter']['Value']

def parse_token(req):
    '''When frontend is built and integrated with an AWS Cognito
       this will parse and decode token to get user identification'''
    return req.headers['Authorization'].split()[1]

def validate_date(date_text):
    try:
        datetime.strptime(date_text, '%Y-%m-%d')
    except ValueError:
        raise ValueError("Incorrect date format, should be YYYY-MM-DD")

def get_chumps_s3(date_filter=DEFAULT_DATE):
    key = "chumps.json"

    print(os.environ)
    print(os.environ['BUCKET_NAME'])
    print(S3_BUCKET_NAME)
    print(key)


    s3_client = boto3.client('s3')
    s3_response_object = s3_client.get_object(Bucket=os.environ['BUCKET_NAME'], Key=key)
    object_content = s3_response_object['Body'].read()
    data = json.loads(object_content)

    filtered_data = [a for a in data if a['date'] > date_filter]

    return filtered_data

def get_chumps(date_filter):
    return get_chumps_s3(date_filter)

@app.route('/')
def index():
    error_message = ""

    try:
        start_date = request.args.get('start_date', DEFAULT_DATE)
        validate_date(start_date)
    except ValueError as ex:
        response['message'] = str(ex)
        return response
    
    print(start_date)
    start_date_parsed = datetime.strptime(start_date, '%Y-%m-%d')
    start_date_parsed_string = start_date_parsed.strftime('%d/%m/%Y')

    print(start_date_parsed_string)

    data = get_chumps(start_date)
    response['data'] = data
    return response
    

@app.route('/update', methods=('POST',))
def UpdateChumps():
    try:
        if parse_token(request) != _get_ssm_param(f"/monty/secret"):
            return jsonify({ "message": "Missing Authentication Token" }), 403
    except Exception as ex:
        return jsonify({ "message": "Missing Authentication Token" }), 403


    return request.get_json()























# @app.route('/lists', methods=('POST',))
# def create_list():
#     list_id = str(uuid.uuid4())
#     try:
#         user_id = parse_user_id(request)
#     except:
#         return jsonify('Unauthorized'), 401

#     list_data = request.get_json()
#     list_data.update(userId=user_id, listId=list_id)
#     tbl = db_table()
#     tbl.put_item(Item=list_data)
#     tbl_response = tbl.get_item(Key={'userId': user_id, 'listId': list_id})
#     return jsonify(tbl_response['Item']), 201


# @app.route('/lists/<string:list_id>')
# def fetch_list(list_id):
#     try:
#         user_id = parse_user_id(request)
#     except:
#         return jsonify('Unauthorized'), 401

#     tbl_response = db_table().get_item(Key={'userId': user_id, 'listId': list_id})
#     return jsonify(tbl_response['Item'])


# @app.route('/lists/<string:list_id>', methods=('PUT',))
# def update_list(list_id):
#     try:
#         user_id = parse_user_id(request)
#     except:
#         return jsonify('Unauthorized'), 401

#     list_data = {k: {'Value': v, 'Action': 'PUT'}
#                 for k, v in request.get_json().items()}
#     tbl_response = db_table().update_item(Key={'userId': user_id, 'listId': list_id},
#                                           AttributeUpdates=list_data)
#     return jsonify()


# @app.route('/lists/<string:list_id>', methods=('DELETE',))
# def delete_list(list_id):
#     try:
#         user_id = parse_user_id(request)
#     except:
#         return jsonify('Unauthorized'), 401

#     db_table().delete_item(Key={'userId': user_id, 'listId': list_id})
#     return jsonify()