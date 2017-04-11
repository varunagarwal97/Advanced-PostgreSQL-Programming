-- Schema: public

-- DROP SCHEMA public;

CREATE SCHEMA public
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public
  IS 'standard public schema';


--K-means algorithm for a 2-dimensional space

CREATE TABLE Points (PId INTEGER, x FLOAT, y FLOAT, PRIMARY KEY (PId));
CREATE TABLE Centroid(CId INTEGER, x FLOAT, y FLOAT);
CREATE TABLE KMeans(PId INTEGER, CId INTEGER, distance FLOAT);

INSERT INTO Points VALUES (1, 0, 0);
INSERT INTO Points VALUES (2, 1, 0);
INSERT INTO Points VALUES (3, 0, 1);
INSERT INTO Points VALUES (4, 4.5, 1.5);
INSERT INTO Points VALUES (5, 7.6, 6.6);
INSERT INTO Points VALUES (6, 2.4, 2.4);
INSERT INTO Points VALUES (7, 1.1, 8.4);
INSERT INTO Points VALUES (8, 2, 5);
INSERT INTO Points VALUES (9, 3.4, 1);
INSERT INTO Points VALUES (10, 4, 6);
INSERT INTO Points VALUES (11, 3.1, 1.5);
INSERT INTO Points VALUES (12, 7.9, 1.5);
INSERT INTO Points VALUES (13, 11.23, 2.91);


CREATE OR REPLACE FUNCTION Distance(x1 FLOAt, y1 FLOAt, x2 FLOAT, y2 FLOAT)
RETURNS FLOAT AS
$$

    SELECT SQRT(POWER(x2 - x1, 2) + POWER(y2 - y1, 2))

$$LANGUAGE SQL


CREATE OR REPLACE FUNCTION Initialise(k INTEGER)
RETURNS VOID AS
$$
    DECLARE
    max_x FLOAT := (SELECT MAX (Points.x) FROm Points);
    max_y FLOAT := (SELECT MAX (Points.y) FROM Points);
    min_x FLOAT := (SELECt MIN (Points.x) FROM Points);
    min_y FLOAT := (SELECT MIN (Points.y) FROM Points);
    pointsrow Points%ROWTYPE;
    
    BEGIN
        DELETE FROM Centroid;

        FOR num IN 1..k LOOP
            INSERT INTO Centroid VALUES(num, (SELECT min_x + (random() * (max_x - min_x))), (SELECT min_y + (random() * (max_y - min_y))));
        END LOOP;  

        DELETE FROM KMeans;
        FOR pointsrow IN SELECT * FROM Points LOOP
            INSERT INTO KMeans VALUES(pointsrow.PId, 0, 0);
        END LOOP;
        
    END
$$LANGUAGE plpgsql;    


CREATE OR REPLACE FUNCTION KMeans(k INTEGER)
RETURNS VOID AS
$$
    DECLARE
    pointsrow Points%ROWTYPE;
    centroidrow Centroid%ROWTYPE;
    centroidrow1 Centroid%ROWTYPE;
    mindist FLOAT;
    
    BEGIN
        PERFORM Initialise(k);
        FOR num IN 1..200 LOOP
            FOR pointsrow IN SELECT * FROM Points LOOP
                SELECT Distance(pointsrow.x, pointsrow.y, (SELECT C.x FROM Centroid C LIMIT 1), (SELECt C.y FROM Centroid C LIMIT 1)) INTO mindist;
                
                FOR centroidrow IN SELECT * FROM Centroid LOOP
                    IF (SELECT Distance(pointsrow.x, pointsrow.y, centroidrow.x, centroidrow.y) <= mindist) THEN
                        mindist := Distance(pointsrow.x, pointsrow.y, centroidrow.x, centroidrow.y);
                        UPDATE KMeans SET CId = centroidrow.CId, distance = mindist WHERE PId = pointsrow.PId;
                    END IF;
                END LOOP;
            END LOOP;
    
            FOR centroidrow1 IN SELECT * FROM Centroid LOOP
                UPDATE Centroid SET x = (SELECT AVG(P.x) FROM Points P, KMeans K 
                                         WHERE P.PId = K.Pid AND K.CId = centroidrow1.CId), 
                                    y = (SELECT AVG(P.y) FROM Points P, KMeans K 
                                         WHERE P.PId = K.Pid AND K.CId = centroidrow1.CId) WHERE CId = centroidrow1.CId;
            END LOOP;
        END LOOP; 
    END
$$ LANGUAGE plpgsql;


SELECT KMeans(2);
SELECT * FROM KMeans;
SELECT * FROM Centroid;
