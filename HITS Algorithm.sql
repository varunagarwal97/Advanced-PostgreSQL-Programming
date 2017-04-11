-- Schema: public

-- DROP SCHEMA public;

CREATE SCHEMA public
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public
  IS 'standard public schema';


--Hyperlink-Induced Topic Search (HITS) algorithm 

CREATE TABLE Graph(source INTEGER, target INTEGER);
CREATE TABLE Nodes(node INTEGER, hubscore FLOAT, authscore FLOAT);

INSERT INTO Graph VALUES(1, 1);
INSERT INTO Graph VALUES(1, 2);
INSERT INTO Graph VALUES(1, 3);
INSERT INTO Graph VALUES(2, 3);
INSERT INTO Graph VALUES(3, 1);
INSERT INTO Graph VALUES(3, 2);

CREATE OR REPLACE FUNCTION InitHITS()
RETURNS VOID AS
$$
    DECLARE
        totalnodes INTEGER;

    BEGIN
        --Initialising Nodes relation
        DELETE from Nodes;
        INSERT INTO Nodes(node, authscore)
        SELECT G1.source, 0 FROM Graph G1 UNION (SELECT G2.target, 0 FROM Graph G2);
        --Setting up initial Hub Scores
        SELECT COUNT (N.node) INTO totalnodes FROM Nodes N;
        UPDATE Nodes SET hubscore = 1/SQRT(totalnodes);
    END
$$LANGUAGE plpgsql;    


CREATE OR REPLACE FUNCTION HITS()
RETURNS VOID AS
$$
    DECLARE
        graphrow Graph%ROWTYPE;
        nodesrow Nodes%ROWTYPE;
        normhub FLOAT;
        normauth FLOAT;

        
    BEGIN
        PERFORM InitHITS();
    
        FOR num in 1..100 LOOP

            --Updating Authority Scores
            FOR nodesrow IN SELECT * FROM Nodes LOOP
                FOR graphrow IN SELECT * FROM Graph LOOP
                    IF graphrow.target = nodesrow.node THEN
                        UPDATE Nodes SET authscore = (authscore + (SELECT N.hubscore FROM Nodes N WHERE N.node = graphrow.source)) 
                        WHERE node = nodesrow.node;
                    END IF;    
                END LOOP;
            END LOOP;

            --Updating Hub Scores
            FOR nodesrow IN SELECT * FROM Nodes LOOP
                FOR graphrow IN SELECT * FROM Graph LOOP
                    IF graphrow.source = nodesrow.node THEN
                        UPDATE Nodes SET hubscore = (hubscore + (SELECT N.authscore FROM Nodes N WHERE N.node = graphrow.target)) 
                        WHERE node = nodesrow.node;
                    END IF;    
                END LOOP;
            END LOOP;

            --Normalizing Scores
            SELECT SQRT(SUM(POW(hubscore, 2))) INTO normhub FROM Nodes;
            SELECT SQRT(SUM(POW(authscore, 2))) INTO normauth FROM Nodes;
            UPDATE Nodes SET hubscore = (hubscore/normhub), authscore = (authscore/normauth);

        END LOOP;
    END

$$ LANGUAGE plpgsql;

SELECT HITS();
SELECT * FROM Nodes ORDER BY node;