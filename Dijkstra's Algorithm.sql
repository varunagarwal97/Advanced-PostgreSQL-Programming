-- Schema: public

-- DROP SCHEMA public;

CREATE SCHEMA public
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public
  IS 'standard public schema';


--Dijkstra's algorithm

CREATE TABLE DGraph(source INTEGER, target INTEGER, weight INTEGER);
CREATE TABLE V(node INTEGER, distance INTEGER);
CREATE TABLE Vertex(node INTEGER);

INSERT INTO DGraph VALUES (0, 1, 2), (0, 4, 10), (1,2,3), (1,4,7), (2,3,4), (3,4,5), (4,2,6), (1, 3, 3), (3, 4, 1);

INSERT INTO Vertex (SELECT D1.source FROM DGraph D1 UNION (SELECT D2.target FROM DGraph D2));



CREATE OR REPLACE FUNCTION Dijkstra(mnode INTEGER)
RETURNS TABLE(Target INTEGER, Distance INTEGER) AS
$$
    DECLARE

        graphrow DGraph%ROWTYPE;
        vrow V%ROWTYPE;
        w INTEGER;
        dw INTEGER;
        dv1 INTEGER;
        dv2 INTEGER;
        dv3 INTEGER;
        
    BEGIN
    
        DELETE FROM V;
        
        drop table if exists S;
        create table S(node integer);

        INSERT INTO S VALUES (mnode);

        INSERT INTO V VALUES (mnode, 0);
        
        FOR graphrow IN (SELECT * FROM DGraph WHERE source = mnode) LOOP
            INSERT INTO V VALUES(graphrow.target, graphrow.weight);
        END LOOP;

        INSERT INTO V (SELECT Vertex.node, -100
                       FROM Vertex
                       EXCEPT
                       (SELECT V.node, -100
                        FROM V)); 

        WHILE EXISTS(SELECT V.node FROM V EXCEPT (SELECT S.node FROM S)) LOOP

            SELECT V.node INTO w
            FROM V
            WHERE V.node NOT IN(SELECT S.node 
                                FROM S)
            AND V.distance <= ALL (SELECT V1.distance FROM V V1 WHERE V1.distance >= 0 
                                   AND V1.node NOT IN(SELECT S.node FROM S))
            AND V.distance >= 0;
            
            SELECT V.distance into dw
            FROM V
            WHERE V.node NOT IN(SELECT S.node 
                                FROM S)
            AND V.distance <= ALL (SELECT V1.distance FROM V V1 WHERE V1.distance >= 0
                                   AND V1.node NOT IN(SELECT S.node FROM S))
            AND V.distance >= 0;
            
            INSERT INTO S VALUEs (w);

            FOR vrow IN (SELECT * FROM V WHERE V.node NOT IN(SELECT S.node FROM S)) LOOP
                SELECT -100 INTO dv1;
                SELECT -100 INTO dv2;
                SELECT -100 INTO dv3;

                IF(vrow.distance != -100) THEN
                     SELECT vrow.distance INTO dv1;
                END IF;

                IF(EXISTS(SELECT D.weight FROM DGraph D WHERE D.source = w AND D.target = vrow.node)) THEN
                     SELECT (D.weight + (SELECT V.distance FROM V WHERE V.node = w)) INTO dv2 
                     FROM DGraph D 
                     WHERE D.source = w 
                     AND D.target = vrow.node;
                END IF;

                IF (dv1 != -100) THEN
                    IF (dv2 != -100) THEN
                        IF(dv1 < dv2) THEN
                            SELECT dv1 INTO dv3;
                        ELSE
                            SELECT dv2 INTO dv3;
                        END IF;
                    ELSE
                        SELECT dv1 INTO dv3;
                    END IF;
                ELSE
                    IF (dv2 != -100) THEN
                        SELECT dv2 INTO dv3;
                    ELSE
                        SELECT -100 INTO dv3;
                    END IF;
                END IF;        

                IF(dv3 != -100) THEN
                    UPDATE V SET distance = dv3 WHERE node = vrow.node;
                END IF;
            END LOOP;
        END LOOP;

        RETURN query SELECT V.node AS Target, V.distance AS Distance FROM V;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM Dijkstra(0) ORDER BY target;
