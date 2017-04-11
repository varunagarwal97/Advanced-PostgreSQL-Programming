-- Schema: public

-- DROP SCHEMA public;

CREATE SCHEMA public
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public
  IS 'standard public schema';

--Map Reduce Program which implements set difference of two relation R(A) and R(B)

CREATE TABLE R2 (A INTEGER);
CREATE TABLE S2 (A INTEGER);
INSERT INTO R2 VALUES (1), (2), (3),(4), (5);
INSERT INTO S2 VALUES (3),(4), (6);



CREATE OR REPLACE FUNCTION Map2(x INTEGER, y INTEGER) 
RETURNS TABLE (a integer, rel integer) AS 
$$
    SELECT x, y;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION Reduce2(x INTEGER, bag_of_rel INTEGER[]) 
RETURNS TABLE(a INTEGER, a1 INTEGER) AS 
$$
BEGIN
    IF (SELECT 2 = ANY(bag_of_rel)) THEN
        RETURN query SELECT x, -x;
    ELSE
        RETURN query SELECt x, x; 
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS key_value;
SELECT * INTO key_value FROM(SELECT s.a AS val, s.rel AS rel
                             FROM R2, LATERAL(SELECT t.a AS a, t.rel AS rel
                             FROM Map2(R2.A, 1) t) s
                             UNION
                             SELECT s1.a AS val, s1.rel AS rel
                             FROM S2, LATERAL(SELECT t1.a AS a, t1.rel AS rel
                             FROM Map2(S2.A, 2) t1) s1) s2;

DROP TABLE IF EXISTS input_reduce;
SELECT distinct K1.val AS val, (select array(select K2.rel 
                                 from  key_value K2 
                                 where K2.val = K1.val)) as rels
INTO input_reduce FROM key_value K1;

SELECT q.a
FROM input_reduce pair, LATERAL(SELECT * 
                                FROM Reduce2(pair.val,pair.rels)) q 
WHERE q.a1 = q.a
order by val;
