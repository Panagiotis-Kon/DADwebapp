# --------------------------------------
# --------------------------------------
DROP PROCEDURE IF EXISTS ValidateQuery;
DELIMITER //
CREATE PROCEDURE ValidateQuery(IN qNum INT, IN queryTableName VARCHAR(255))
BEGIN
	DECLARE cname VARCHAR(64);
	DECLARE done INT DEFAULT FALSE;
	DECLARE cur CURSOR FOR SELECT c.column_name FROM information_schema.columns c WHERE 
c.table_schema='movies' AND c.table_name=queryTableName;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	# Add the column fingerprints into a tmp table
	DROP TABLE IF EXISTS cFps;
	CREATE TABLE cFps (
  	  `val` VARCHAR(50) NOT NULL
	) 
	ENGINE = InnoDB;

	OPEN cur;
	read_loop: LOOP
		FETCH cur INTO cname;
		IF done THEN
      			LEAVE read_loop;
    		END IF;
		
		DROP TABLE IF EXISTS ordered_column;
		SET @order_by_c = CONCAT('CREATE TABLE ordered_column as SELECT ', cname, ' FROM ', queryTableName, ' ORDER BY ', cname);
		PREPARE order_by_c_stmt FROM @order_by_c;
		EXECUTE order_by_c_stmt;
		
		SET @query = CONCAT('SELECT md5(group_concat(', cname, ', "")) FROM ordered_column INTO @cfp');
		PREPARE stmt FROM @query;
		EXECUTE stmt;

		INSERT INTO cFps values(@cfp);
		DROP TABLE IF EXISTS ordered_column;
	END LOOP;
	CLOSE cur;

	# Order fingerprints
	DROP TABLE IF EXISTS oCFps;
	SET @order_by = 'CREATE TABLE oCFps as SELECT val FROM cFps ORDER BY val'; 
	PREPARE order_by_stmt FROM @order_by;
	EXECUTE order_by_stmt;

	# Read the values of the result
	SET @q_yours = 'SELECT md5(group_concat(val, "")) FROM oCFps INTO @yours';
	PREPARE q_yours_stmt FROM @q_yours;
	EXECUTE q_yours_stmt;

	SET @q_fp = CONCAT('SELECT fp FROM fingerprints WHERE qnum=', qNum,' INTO @rfp');
	PREPARE q_fp_stmt FROM @q_fp;
	EXECUTE q_fp_stmt;

	SET @q_diagnosis = CONCAT('select IF(@rfp = @yours, "OK", "ERROR") into @diagnosis');
	PREPARE q_diagnosis_stmt FROM @q_diagnosis;
	EXECUTE q_diagnosis_stmt;

	INSERT INTO results values(qNum, @rfp, @yours, @diagnosis);

	DROP TABLE IF EXISTS cFps;
	DROP TABLE IF EXISTS oCFps;
END//
DELIMITER ;

# --------------------------------------

# Execute queries (Insert here your queries).

# Validate the queries
drop table if exists results;
CREATE TABLE results (
  `qnum` INTEGER  NOT NULL,
  `rfp` VARCHAR(50)  NOT NULL,
  `yours` VARCHAR(50)  NOT NULL,
  `diagnosis` VARCHAR(10)  NOT NULL
)
ENGINE = InnoDB;


# -------------
# Q1
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select movie.title
from movie, actor, genre, role, movie_has_genre
where actor.last_name = 'Allen'
	  and role.movie_id = movie.movie_id
	  and role.actor_id = actor.actor_id
	  and genre.genre_id = movie_has_genre.genre_id
	  and movie_has_genre.movie_id = movie.movie_id
	  and genre.genre_name = 'Comedy';

CALL ValidateQuery(1, 'q');
drop table if exists q;
# -------------


# -------------
# Q2
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct d.last_name, m.title
from movie as m, director as d, actor, role  as r, movie_has_director as mhd
where actor.last_name = 'Allen'
	  and r.movie_id = m.movie_id
      and r.actor_id = actor.actor_id
      and mhd.movie_id = m.movie_id
      and mhd.director_id = d.director_id
      and d.director_id in(select d.director_id
                           from movie as m1, movie as m2, director as d, movie_has_genre as mhg1, movie_has_genre as mhg2, genre as g1, genre as g2, movie_has_director as mhd1, movie_has_director as mhd2
						   where mhd1.movie_id = m1.movie_id
                                 and mhd1.director_id = d.director_id
								 and mhg1.movie_id = m1.movie_id
                                 and mhg1.genre_id = g1.genre_id
                                 # ena eidos apo mia tainia
                                 and mhd2.movie_id = m2.movie_id
                                 and mhd2.director_id = d.director_id
								 and mhg2.movie_id = m2.movie_id
                                 and mhg2.genre_id = g2.genre_id
                                 # allo eidos apo allh tainia
                                 and g1.genre_id != g2.genre_id);

CALL ValidateQuery(2, 'q');
drop table if exists q;
# -------------


# -------------
# Q3
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct actor.last_name
from movie as m, director as d1, director as d2, actor, movie_has_genre as mhg, genre as g, role  as r, movie_has_director as mhd
where actor.last_name = d1.last_name
	  and r.movie_id = m.movie_id
      and r.actor_id = actor.actor_id
      and mhd.movie_id = m.movie_id
      and mhd.director_id = d1.director_id
      # mexri edo proto erothma
      and actor.last_name != d2.last_name
      and d2.director_id in(select distinct d2.director_id
                            from movie as m1, movie as m2, director as d1, director as d2, movie_has_genre as mhg1, movie_has_genre as mhg2, genre as g1, genre as g2, role  as r1, role  as r2, movie_has_director as mhd1,  movie_has_director as mhd2
							where r1.movie_id = m1.movie_id
                                  and r1.actor_id != actor.actor_id
								  #den paizei sthn tainia tou d1
                                  and mhd1.movie_id = m1.movie_id
                                  and mhd1.director_id = d1.director_id
								  and mhg1.movie_id = m1.movie_id
                                  and mhg1.genre_id = g1.genre_id
                                  and d1.director_id != d2.director_id
								  and m1.movie_id != m2.movie_id
                                  and r2.movie_id = m2.movie_id
                                  and r2.actor_id = actor.actor_id
								  #paizei sthn tainia tou d2
								  and mhd2.movie_id = m2.movie_id
								  and mhd2.director_id = d2.director_id
								  and mhg2.movie_id = m2.movie_id
                                  and mhg2.genre_id = g2.genre_id
                                  and g1.genre_id = g2.genre_id);

CALL ValidateQuery(3, 'q');
drop table if exists q;
# -------------


# -------------
# Q4
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

(select "yes"
from movie as m1
where exists (select *
              from movie as m1, movie_has_genre as mhg, genre as g
              where g.genre_name = 'Drama'
              and g.genre_id = mhg.genre_id
	          and mhg.movie_id = m1.movie_id
			  and m1.year = '1995'))
union
(select "no"
from movie as m2
where not exists (select *
              from movie as m2, movie_has_genre as mhg, genre as g
              where g.genre_name = 'Drama'
              and g.genre_id = mhg.genre_id
	          and mhg.movie_id = m2.movie_id
			  and m2.year = '1995'));

CALL ValidateQuery(4, 'q');
drop table if exists q;
# -------------


# -------------
# Q5
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select d1.last_name as 1stdirector, d2.last_name as 2nddirector
from movie as m, director as d1, director as d2, movie_has_director as mhd1, movie_has_director as mhd2
where d1.director_id < d2.director_id
      and (m.year between 2000 and 2006)
      and m.movie_id = mhd1.movie_id
      and mhd1.director_id = d1.director_id
      and m.movie_id = mhd2.movie_id
      and mhd2.director_id = d2.director_id
      and (select count(distinct mhg1.genre_id)
	       from movie as m1, movie_has_genre as mhg1, genre as g1, movie_has_director as mhd1
	       where m1.movie_id = mhd1.movie_id
	             and mhd1.director_id = d1.director_id
	             and m1.movie_id = mhg1.movie_id
	             and mhg1.genre_id = g1.genre_id) >= 6
#o d1 sxetizetai me toulaxiston 6 eidh
      and (select count(distinct mhg2.genre_id)
	       from movie as m2, movie_has_genre as mhg2, genre as g2, movie_has_director as mhd2
	       where m2.movie_id = mhd2.movie_id
	             and mhd2.director_id = d2.director_id
	             and m2.movie_id = mhg2.movie_id
	             and mhg2.genre_id = g2.genre_id) >= 6;
#o d2 sxetizetai me toulaxiston 6 eidh

CALL ValidateQuery(5, 'q');
drop table if exists q;
# -------------


# -------------
# Q6
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct actor.first_name as first_name, actor.last_name as last_name,
(select count(distinct d.director_id)
 from role as r, movie as m, movie_has_director as mhd, director as d
 where actor.actor_id = r.actor_id
       and r.movie_id = m.movie_id
       and m.movie_id = mhd.movie_id
       and mhd.director_id = d.director_id
) as count
#o arithmos ton diaforetikon skhnotheton pou exoun oi tainies tou actor
from actor, movie, role, movie_has_director mhd1, director
where (select count(role.movie_id)
	       from movie as m1, role as r1
	       where m1.movie_id = r1.movie_id
	             and r1.actor_id = actor.actor_id) = 3
#o actor exei paiksei se akribos 3 tainies
      and actor.actor_id = role.actor_id
      and role.movie_id = movie.movie_id
	  and movie.movie_id = mhd1.movie_id
      and mhd1.director_id = director.director_id;

CALL ValidateQuery(6, 'q');
drop table if exists q;
# -------------


# -------------
# Q7
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct genre.genre_id,
(select count(distinct d.director_id)
 from movie as m, movie_has_director as mhd, director as d, movie_has_genre as mhg
 where genre.genre_id = mhg.genre_id
       and mhg.movie_id = m.movie_id
       and m.movie_id = mhd.movie_id
       and mhd.director_id = d.director_id
) as count
#o arithmos skhnotheton pou exoun skhnothethsei to eidos ayto
from genre, movie, movie_has_director mhd1, director, movie_has_genre as mhg1
where (select count(mhg2.genre_id)
	       from genre as g1, movie_has_genre as mhg2
	       where movie.movie_id = mhg2.movie_id
	             and mhg2.genre_id = g1.genre_id) = 1
#h tainia exei akribos ena eidos
      and movie.movie_id = mhd1.movie_id
      and mhd1.director_id = director.director_id
      and movie.movie_id = mhg1.movie_id
      and mhg1.genre_id = genre.genre_id;

CALL ValidateQuery(7, 'q');
drop table if exists q;
# -------------


# -------------
# Q8
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct actor.actor_id
from actor, genre as g
where (select count(distinct g1.genre_id)
	   from movie, role, movie_has_genre mhg, genre as g1
       where actor.actor_id = role.actor_id
			and role.movie_id = movie.movie_id
            and movie.movie_id = mhg.movie_id
            and mhg.genre_id = g1.genre_id)
= (select count(distinct g.genre_id)
   from genre as g);
#o arithmos ton eidon pou exei paiksei o hthopoios einai isos me ton
#synoliko arithmo ton diaforetikon eidon ton tainion

CALL ValidateQuery(8, 'q');
drop table if exists q;
# -------------


# -------------
# Q9
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct g1.genre_id as 1stgenre_id, g2.genre_id as 2ndgenre_id,count(distinct director.director_id) as count
from genre as g1, genre as g2, movie as m1, movie as m2, movie_has_genre as mhg1, movie_has_genre as mhg2, director, movie_has_director as mhd1, movie_has_director as mhd2
where g1.genre_id < g2.genre_id
       and m1.movie_id = mhd1.movie_id
	   and mhd1.director_id = director.director_id
       and m1.movie_id = mhg1.movie_id 
       and mhg1.genre_id = g1.genre_id
       and m2.movie_id = mhd2.movie_id
	   and mhd2.director_id = director.director_id
       and m2.movie_id = mhg2.movie_id 
       and mhg2.genre_id = g2.genre_id
group by g1.genre_id, g2.genre_id;

CALL ValidateQuery(9, 'q');
drop table if exists q;
# -------------


# -------------
# Q10
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

select distinct genre.genre_id as genre_id, actor.actor_id as actor_id, count(distinct role.movie_id) as count
from genre, actor, movie, director, movie_has_genre as mhg, role, movie_has_director as mhd
where genre.genre_id = mhg.genre_id
       and mhg.movie_id = movie.movie_id
       and movie.movie_id = role.movie_id
       and role.actor_id = actor.actor_id
       and director.director_id = mhd.director_id
	   and mhd.movie_id = movie.movie_id
       and (select count(distinct mhg1.genre_id)
			from movie as m1, movie_has_genre as mhg1, genre as g1, movie_has_director as mhd1
            where director.director_id = mhd1.director_id
	              and mhd1.movie_id = m1.movie_id
                  and m1.movie_id = mhg1.movie_id
                  and mhg1.genre_id = g1.genre_id) = 1
#o skhnotheths exei skhnothethsei ena eidos
       and director.director_id = all (select d2.director_id
			from director as d2, movie_has_director as mhd2
            where d2.director_id = mhd2.director_id
	              and mhd2.movie_id = movie.movie_id)
#oloi oi skhnothetes ths tainias exoun skhnothethsei ena eidos
group by genre.genre_id, actor.actor_id;

CALL ValidateQuery(10, 'q');
drop table if exists q;
# -------------

DROP PROCEDURE IF EXISTS RealValue;
DROP PROCEDURE IF EXISTS ValidateQuery;
DROP PROCEDURE IF EXISTS RunRealQueries;

select * from results;