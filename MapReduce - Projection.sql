-- Schema: public

-- DROP SCHEMA public;

CREATE SCHEMA public
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public
  IS 'standard public schema';

--Map Reduce Program which implements Projection of A from relation R, where R(A, B) is a relation.

CREATE TABLE R1 (A INTEGER, B INTEGER);

INSERT INTO R1 VALUES (1, 1), (1, 2), (2, 2), (3, 4), (3, 1), (3, 2), (4, 5);

CREATE OR REPLACE FUNCTION Map1(x INTEGER, y INTEGER) 
RETURNS TABLE (a integer, one integer) AS 
$$
    SELECT x, 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION Reduce(x INTEGER, bag_of_ones INTEGER[]) 
RETURNS TABLE(a INTEGER) AS 
$$
    SELECT x; 
$$ LANGUAGE SQL;


DROP TABLE IF EXISTS key_value;
SELECT s.a AS word, s.one AS one
INTO key_value FROM R1, LATERAL(SELECT t.a, t.one 
                                                  FROM Map1(R1.A ,R1.B) t) s;

DROP TABLE IF EXISTS input_reduce;
SELECT distinct K1.word AS word, (select array(select K2.one 
                               from  key_value K2 
                               where K2.word = K1.word)) as ones
INTO input_reduce FROM key_value K1;

SELECT q.a
FROM input_reduce pair, LATERAL(SELECT * 
                                FROM reduce(pair.word,pair.ones)) q 
order by q.a;                     