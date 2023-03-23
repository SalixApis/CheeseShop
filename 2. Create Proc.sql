USE DATABASE DEV_DB;
USE ROLE SYSADMIN;
USE SCHEMA SCHEMACHANGE;

CREATE OR REPLACE PROCEDURE DEPLOY_RBAC_ROLES_FOR_SCHEMA(DATABASENAME STRING, SCHEMANAME STRING)
    RETURNS VARCHAR()
    LANGUAGE SQL
    EXECUTE AS CALLER
AS 
$$

DECLARE
    ENV_DB STRING := :DATABASENAME;
    TARGET_SCHEMA STRING := :SCHEMANAME;

    FULL_ROLE STRING := '_' || :ENV_DB || '_' || :TARGET_SCHEMA || '_FULL';
    READWRITE_ROLE STRING := '_' || :ENV_DB || '_' || :TARGET_SCHEMA || '_RW';
    READ_ROLE STRING := '_' || :ENV_DB || '_' || :TARGET_SCHEMA || '_R';
    OPS_ROLE STRING := '_' || :ENV_DB || '_' || :TARGET_SCHEMA || '_OPS';

    RESULTSTRING STRING := '';
BEGIN
    
    IF (CONTAINS(CURRENT_AVAILABLE_ROLES(), 'USERADMIN') AND CONTAINS(CURRENT_AVAILABLE_ROLES(), 'SYSADMIN')) THEN
        
        --CREATE ROLES
        USE ROLE USERADMIN;
        EXECUTE IMMEDIATE 'CREATE ROLE IF NOT EXISTS ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT ROLE ' || :FULL_ROLE || ' TO ROLE SYSADMIN';
        EXECUTE IMMEDIATE 'CREATE ROLE IF NOT EXISTS ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT ROLE ' || :READWRITE_ROLE || ' TO ROLE SYSADMIN';
        EXECUTE IMMEDIATE 'CREATE ROLE IF NOT EXISTS ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT ROLE ' || READ_ROLE || ' TO ROLE SYSADMIN';
        EXECUTE IMMEDIATE 'CREATE ROLE IF NOT EXISTS ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT ROLE ' || :OPS_ROLE || ' TO ROLE SYSADMIN';

        --BEGIN GRANTS
        USE ROLE SYSADMIN;

        --Remove any exisiting future grants in the schema
        EXECUTE IMMEDIATE 'SHOW FUTURE GRANTS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA;
    
        LET ownercursor CURSOR FOR 
            SELECT 
                REPLACE($3,'_',' ') AS GRANT_ON,
                $5 AS GRANT_TO,
                $6 AS GRANTEE_NAME
            FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
            WHERE $2 = 'OWNERSHIP';
        
        FOR r1 IN ownercursor DO
            EXECUTE IMMEDIATE 'REVOKE OWNERSHIP ON FUTURE ' || r1.GRANT_ON || 'S IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' FROM ROLE ' || r1.GRANTEE_NAME;
        END FOR;

        EXECUTE IMMEDIATE 'SHOW FUTURE GRANTS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA;
        LET other_priv_cursor CURSOR FOR 
            SELECT
                DISTINCT
                REPLACE($3,'_',' ') AS GRANT_ON,
                $5 AS GRANT_TO,
                $6 AS GRANTEE_NAME
            FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
            WHERE $2 <> 'OWNERSHIP';
        
        FOR r2 IN other_priv_cursor DO
            EXECUTE IMMEDIATE 'REVOKE ALL ON FUTURE ' || r2.GRANT_ON || 'S IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' FROM ROLE ' || r2.GRANTEE_NAME;
        END FOR;

        --FUTURES TO FULL ROLL
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :ENV_DB || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE FILE FORMATS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE FUNCTIONS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE SEQUENCES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE STAGES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE STREAMS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        -- EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE TAGS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE; -- Future grants of privileges on tags are not supported.
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON FUTURE VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE;

        --FUTURES TO READWRITE
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :ENV_DB || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE FILE FORMATS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE FUNCTIONS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR ON FUTURE PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SEQUENCES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE, READ, WRITE ON FUTURE STAGES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE STREAMS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, TRUNCATE, DELETE, REFERENCES ON FUTURE TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        -- EXECUTE IMMEDIATE 'GRANT APPLY ON FUTURE TAGS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE; -- Future grants of privileges on tags are not supported.
        EXECUTE IMMEDIATE 'GRANT MONITOR ON FUTURE TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;

        --FUTURES TO READ
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :ENV_DB || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE FILE FORMATS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE FUNCTIONS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR ON FUTURE PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE, READ ON FUTURE STAGES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE STREAMS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR ON FUTURE TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON FUTURE VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;

        --FUTURES TO OPS
        EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || :ENV_DB || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON FUTURE EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON FUTURE MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR,OPERATE ON FUTURE PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON FUTURE TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR,OPERATE ON FUTURE TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON FUTURE VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;

        --EXISITING TO FULL
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL FILE FORMATS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL FUNCTIONS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        -- EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS'; -- Bulk Grants to Pipes are not allowed
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL SEQUENCES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL STAGES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL STREAMS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        -- EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL TAGS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS'; -- Bulk Grants of tags does not appear to be supported
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';
        EXECUTE IMMEDIATE 'GRANT OWNERSHIP ON ALL VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :FULL_ROLE || ' REVOKE CURRENT GRANTS';

        --EXISITING TO READWRITE
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL FILE FORMATS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL FUNCTIONS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        -- EXECUTE IMMEDIATE 'GRANT MONITOR ON ALL PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE; -- Bulk Grants to Pipes are not allowed
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL SEQUENCES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE, READ, WRITE ON ALL STAGES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT ON ALL STREAMS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, TRUNCATE, DELETE, REFERENCES ON ALL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        -- EXECUTE IMMEDIATE 'GRANT APPLY ON ALL TAGS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE; -- Bulk Grants of tags does not appear to be supported
        EXECUTE IMMEDIATE 'GRANT MONITOR ON ALL TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READWRITE_ROLE;

        --EXISITING TO READ
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL FILE FORMATS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL FUNCTIONS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        -- EXECUTE IMMEDIATE 'GRANT MONITOR ON ALL PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE; -- Bulk Grants to Pipes are not allowed
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT USAGE, READ ON ALL STAGES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT ON ALL STREAMS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR ON ALL TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;
        EXECUTE IMMEDIATE 'GRANT SELECT, REFERENCES ON ALL VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :READ_ROLE;

        --EXISITING TO OPS
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON ALL EXTERNAL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON ALL MATERIALIZED VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        -- EXECUTE IMMEDIATE 'GRANT MONITOR,OPERATE ON ALL PIPES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE; -- Bulk Grants to Pipes are not allowed
        EXECUTE IMMEDIATE 'GRANT USAGE ON ALL PROCEDURES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON ALL TABLES IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT MONITOR,OPERATE ON ALL TASKS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;
        EXECUTE IMMEDIATE 'GRANT REFERENCES ON ALL VIEWS IN SCHEMA ' || :ENV_DB || '.' || :TARGET_SCHEMA || ' TO ROLE ' || :OPS_ROLE;

        RESULTSTRING := 'Sucessfully Created ' || :FULL_ROLE || ', ' || :READWRITE_ROLE || ', ' || :READ_ROLE || ', ' || :OPS_ROLE || ' in database ' || :ENV_DB || '.';

    ELSE
        RESULTSTRING := 'Unable to generate roles. Executing User Must Have access to USERADMIN AND SYSADMIN roles';
    END IF;

    RETURN :RESULTSTRING;
EXCEPTION
    WHEN statement_error then
        return object_construct('Error type', 'STATEMENT_ERROR',
                            'SQLCODE', sqlcode,
                            'SQLERRM', sqlerrm,
                            'SQLSTATE', sqlstate);
END
$$;
