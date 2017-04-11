-- Schema: public

-- DROP SCHEMA public;

CREATE SCHEMA public
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public
  IS 'standard public schema';

--Map Reduce Program that implements natural join R X S of two relations R(A, B) and S(B, C)

CREATE TABLE R3 (A INTEGER, B INTEGER);
CREATE TABLE S3 (B INTEGER, C INTEGER);
INSERT INTO R3 VALUES (1, 1), (3, 2), (2, 3),(5, 4), (6, 5);
INSERT INTO S3 VALUES (1, 3),(3, 4), (7, 6), (1, 10);


CREATE TYPE records AS (
  val   INTEGER,
  tablename  integer
);


CREATE OR REPLACE FUNCTION Map3(x INTEGER, y INTEGER, z INTEGER) 
RETURNS TABLE (a integer, rel records) AS 
$$
    DECLARE
        var records;

    BEGIN
        SELECT z INTO var.tablename;
        SELECT y INTO var.val;
        RETURN query SELECT x, var;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION Reduce3(bval INTEGER, bag_of_rel records[]) 
RETURNS TABLE(a INTEGER, b INTEGER, c INTEGER) AS 
$$
DECLARE
    num RECORD;
    num1 RECORD;

BEGIN
    DROP TABLE IF EXISTS split;
    CREATE TABLE split (x INTEGER, wd records);
    INSERT INTO split (SELECT bval AS x, w.wd AS wd FROM (SELECT UNNEST(rels) AS wd FROM input_reduce WHERE val = bval) w);

    drop table if exists final;
    create table final(A integer, B INTEGER, C INTEGER);

    FOR num in (SELECt * FROM split WHERE (split.wd).tablename = 1) LOOP
        
        FOR num1 IN (SELECT * FROM split WHERE (split.wd).tablename = 2) LOOP
            INSERT INTO final VALUES ((num.wd).val, num.x, (num1.wd).val);
        END LOOP;

    END LOOP;
    RETURN query SELECT * FROM final;
END;                    
$$ LANGUAGE plpgsql;


DROP TABLE IF EXISTS key_value;
SELECT * INTO key_value FROM (SELECT s.a AS val, s.rel AS rel
                              FROM R3, LATERAL(SELECT t.a AS a, t.rel AS rel
                              FROM Map3(R3.A, R3.B, 1) t) s
                              UNION
                              SELECT s1.a AS val, s1.rel AS rel
                              FROM S3, LATERAL(SELECT t1.a AS a, t1.rel AS rel
                              FROM Map3(S3.B, S3.C, 2) t1) s1) s2;


DROP TABLE IF EXISTS input_reduce;
SELECT distinct K1.val AS val, (select array(select K2.rel 
                                from  key_value K2 
                                where K2.val = K1.val)) as rels
INTO input_reduce FROM key_value K1;


SELECT q.a, q.b, q.c
FROM input_reduce pair, LATERAL(SELECT * 
                                FROM Reduce3(pair.val,pair.rels)) q;



