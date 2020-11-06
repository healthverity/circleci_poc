""" Handles connecting to and making queries to the Pennyworth db. """

import json
from binascii import unhexlify
from contextlib import closing

import psycopg2
import boto3

import sql


CONN = None

def _get_credentials(name) -> dict:
    """ Retrieves credentials from ssm. """
    ssm_client = boto3.client('ssm')
    return json.loads(
        ssm_client.get_parameter(
            Name=name,
            WithDecryption=True,
        )['Parameter']['Value'])

def start_connection(stage):
    """ Starts a connection to the pennyworth db. """
    db_info = get_pennyworth_db_credentials(stage)
    global CONN
    CONN = psycopg2.connect(
        dbname=db_info['database'],
        user=db_info['user'],
        password=db_info['password'],
        host=db_info['host'],
        port=db_info['port'])

def close_connection():
    """ Closes the connection to the pennyworth db. """
    if CONN:
        CONN.close()

##################################
# Pennyworth DB methods
##################################

def get_pennyworth_db_credentials(stage) -> dict:
    """
    Retrieves pennyworth database credentials.

    Args:
    stage -- the environment whose database to connect to

    Returns:
    credentials -- the credentials needed to connect to the requested database
    """
    if stage == 'local':
        return {
            'host': 'localhost',
            'port': '32768',
            'database': 'config',
            'user': 'postgres',
            'password': ''
        }
    return _get_credentials(f'{stage}-marketplace-rds_su_db_conn')

def lookup_auth_group_id(user_type):
    """
    Return auth group ID for a given user_type (group name).

    Args:
    user_type -- the type of user whose auth_group ID is being searched for

    Returns:
    auth_group_id -- the ID of the auth_group the requested user is in
    """
    row = None
    with closing(CONN.cursor()) as cursor:
        try:
            cursor.execute(sql.LOOKUP_GROUP_ID.format(user_type=user_type))
            row = cursor.fetchone()
        except psycopg2.errors.InFailedSqlTransaction:
            print(f'Error getting auth group id for {user_type}')
            CONN.rollback()
    if not row:
        raise Exception(f'No auth_group found for {user_type}')
    return row[0]

def get_user_profile_id(username):
    """
    Returns the specified user type's user_profile ID.

    Args:
    username -- the username of the user whose ID is being searched for

    Returns:
    user_profile_id -- the ID of the requested user's user_profile
    """
    with closing(CONN.cursor()) as cursor:
        cursor.execute(sql.GET_USER_PROFILE_ID.format(username=username))
        return cursor.fetchone()[0]

def setup_user(username, user_type, password_hash, tos_agreed=True):
    """
    Creates a test user for Selenium tests if it does not exist.

    Args:
    username -- the username to use when creating the new user
    user_type -- the type of user to be created
    password_hash -- the password hash to use when creating the new user
    tos_agreed -- whether or not the user will have agreed to the terms of service

    Returns:
    user_profile_id -- the ID of the created user's user_profile entry
    """
    group_id = lookup_auth_group_id(user_type)

    with closing(CONN.cursor()) as cursor:
        # Create auth_user
        try:
            cursor.execute(sql.CREATE_USER.format(username=username,
                                                  user_type=user_type,
                                                  password_hash=password_hash))
            new_user_id = cursor.fetchone()[0]
        except psycopg2.IntegrityError:
            print(f'{user_type} user already exists')
            CONN.rollback()
            return get_user_profile_id(username)

        # Create auth_user_group entry
        cursor.execute(sql.CREATE_USER_GROUP.format(user_id=new_user_id, group_id=group_id))

        # Create user profile and org relation
        cursor.execute(sql.CREATE_USER_PROFILE.format(user_id=new_user_id))
        userprofile_id = cursor.fetchone()[0]
        cursor.execute(sql.CREATE_USER_ORG.format(user_id=userprofile_id))

        if tos_agreed:
            # create user aggreement
            cursor.execute(sql.CREATE_USER_AGREEMENT.format(user_id=new_user_id))

    CONN.commit()
    return get_user_profile_id(username)

##################################
# General helper methods
##################################

def escape_single_quotes(string: str) -> str:
    """ Escapes all single quotes in a string for use in a SQL query. """
    return string.replace("'", "''")

def get_test_user_credentials(stage) -> dict:
    """ Returns the login user credentials as well as the password hash for user creation."""
    if stage == 'local':
        return {
            'usertype': {
                'username': 'local_user',
                'password': 'testit123',
                'passhash': 'bcrypt_sha256$$2b$12$o9mISXPiWZQzO3WcKIB2MuDqGKNNw3ZHW.hhMYpybIPYmLXCfcwGG'
            },
        }
    return _get_credentials(f'{stage}-pennyworth-test-user-creds')
