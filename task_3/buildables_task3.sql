------------------------------- Step-1
CREATE TABLE dim_ps5_games (
 game_sk SERIAL PRIMARY KEY, 
 game_id INT NOT NULL, 
 title VARCHAR(255),
 genre VARCHAR(100),
 developer VARCHAR(100),
 price NUMERIC(10,2),
 ps_plus_included BOOLEAN,
 row_hash TEXT, 
 start_date TIMESTAMP NOT NULL,
 end_date TIMESTAMP,
 is_active BOOLEAN DEFAULT TRUE
);

--only one active version per game_id
CREATE UNIQUE INDEX ux_dim_ps5_games_one_active_per_game
ON dim_ps5_games (game_id)
WHERE is_active IS TRUE;


CREATE TABLE stg_ps5_games (
 game_id INT NOT NULL,
 title VARCHAR(255),
 genre VARCHAR(100),
 developer VARCHAR(100),
 price NUMERIC(10,2),
 ps_plus_included BOOLEAN,
 row_hash TEXT
);

----------------------------- Step-2

WITH my_cte AS (
  SELECT * FROM (
    VALUES
      (1001, 'Spider-Man 2', 'Action', 'Insomniac Games', 69.99::numeric, TRUE),
      (1002, 'Demon''s Souls', 'RPG', 'Bluepoint Games', 59.99::numeric, FALSE),
      (1003, 'Returnal', 'Roguelike', 'Housemarque', 69.99::numeric, FALSE)
  ) v(game_id, title, genre, developer, price, ps_plus_included)
),
hashed AS (
  SELECT
    game_id, title, genre, developer, price, ps_plus_included,
    md5(concat_ws('||',
        game_id::text,
        coalesce(title,''),
        coalesce(genre,''),
        coalesce(developer,''),
        coalesce(price::text,''),
        coalesce(ps_plus_included::text,'')
    )) AS row_hash
  FROM my_cte
)
INSERT INTO dim_ps5_games (
  game_id, title, genre, developer, price, ps_plus_included,
  row_hash, start_date, end_date, is_active
)

SELECT *
FROM dim_ps5_games
ORDER BY game_id, game_sk;


INSERT INTO stg_ps5_games (game_id, title, genre, developer, price, ps_plus_included, row_hash)
SELECT
  game_id, title, genre, developer, price, ps_plus_included,
  md5(concat_ws('||',
      game_id::text,
      coalesce(title,''),
      coalesce(genre,''),
      coalesce(developer,''),
      coalesce(price::text,''),
      coalesce(ps_plus_included::text,'')
  ))
FROM (
  VALUES
    -- Spiderman price drop
    (1001, 'Spider-Man 2', 'Action', 'Insomniac Games', 49.99::numeric, TRUE),

    -- Demon’s Souls included in PS Plus
    (1002, 'Demon''s Souls', 'RPG', 'Bluepoint Games', 59.99::numeric, TRUE),

    -- unchanged
    (1003, 'Returnal', 'Roguelike', 'Housemarque', 69.99::numeric, FALSE),

    -- NEW
    (1004, 'Ghost of Tsushima Director''s Cut', 'Action Adventure', 'Sucker Punch Productions', 49.99::numeric, FALSE)
) s(game_id, title, genre, developer, price, ps_plus_included);

SELECT *
FROM stg_ps5_games;

SELECT
  s.*,
  CASE
    WHEN d.game_id IS NULL THEN 'NEW'
    WHEN d.row_hash = s.row_hash THEN 'NOT_CHANGED'
    ELSE 'CHANGED'
  END AS change_flag
FROM stg_ps5_games s
LEFT JOIN dim_ps5_games d
  ON d.game_id = s.game_id
 AND d.is_active = TRUE
ORDER BY s.game_id;


-------------------------------------- Step-3
-- Closing active rows that changed
UPDATE dim_ps5_games d
SET end_date = now(),
    is_active = FALSE
FROM stg_ps5_games s
WHERE d.game_id = s.game_id
  AND d.is_active = TRUE
  AND d.row_hash IS DISTINCT FROM s.row_hash;
  

-- Inserting new ACTIVE rows for both:
INSERT INTO dim_ps5_games (
  game_id, title, genre, developer, price, ps_plus_included,
  row_hash, start_date, end_date, is_active
)
SELECT
  s.game_id, s.title, s.genre, s.developer, s.price, s.ps_plus_included,
  s.row_hash, now(), NULL, TRUE
FROM stg_ps5_games s
LEFT JOIN dim_ps5_games d
  ON d.game_id = s.game_id
 AND d.is_active = TRUE
WHERE d.game_id IS NULL;  

----------------------------- Step-4 before/after data

SELECT 'FINAL_DIM' AS tag, d.*
FROM dim_ps5_games d
ORDER BY game_id, game_sk;

SELECT 'FINAL_ACTIVE_ONLY' AS tag, d.*
FROM dim_ps5_games d
WHERE d.is_active
ORDER BY game_id;
