-- Updating multiple columns, is that too easy?
UPDATE actornew
SET "FilmCount" =
    (SELECT count(title) FilmCount
        FROM Actor a
        INNER JOIN Film_Actor fa on a.actor_id = fa.actor_id
        INNER JOIN Film f ON fa.film_id = f.film_id
        WHERE a.actor_id = actornew.actor_id
        GROUP BY a.actor_id),
    last_update = now()
