"""
SQL queries for use in the pennyworth UAT.
These queries assume use/format of the rockefeller db.
"""

CREATE_USER = """
    INSERT INTO auth_user (
        username,
        first_name,
        last_name,
        email,
        password,
        is_superuser,
        is_staff,
        is_active,
        date_joined
    )
    VALUES (
        '{username}',
        'Test',
        '{user_type}',
        'qa_automation@healthverity.com',
        '{password_hash}',
        'f',
        'f',
        't',
        current_timestamp
    ) RETURNING id;
"""

CREATE_USER_GROUP = """
    INSERT INTO auth_user_groups (user_id, group_id)
    VALUES ({user_id}, {group_id});
"""

CREATE_USER_PROFILE = """
    INSERT INTO organization_userprofile (user_id)
    VALUES ({user_id}) RETURNING id;
"""

GET_USER_PROFILE_ID = """
    SELECT id
    FROM organization_userprofile
    WHERE user_id = (
        SELECT id
        FROM auth_user
        WHERE username='{username}'
    );
"""

CREATE_USER_ORG = """
    INSERT INTO organization_userprofile_organization (userprofile_id, organization_id)
    VALUES ({user_id}, 1); -- 1 is HealthVerity
"""

CREATE_USER_AGREEMENT = """
    INSERT INTO tos_useragreement (user_id, terms_of_service_id, created, modified)
    VALUES (
        {user_id},
        (SELECT id from tos_termsofservice order by id desc limit 1),
        current_timestamp,
        current_timestamp
    );
"""

LOOKUP_GROUP_ID = """
    SELECT id
    FROM auth_group
    where name = '{user_type}';
"""
