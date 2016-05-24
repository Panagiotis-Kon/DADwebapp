# ----- CONFIGURE YOUR EDITOR TO USE 4 SPACES PER TAB ----- #
import pymysql as db
import settings
import sys

def connection():
    ''' User this function to create your connections '''
    con = db.connect(
        settings.mysql_host, 
        settings.mysql_user, 
        settings.mysql_passwd, 
        settings.mysql_schema)
    
    return con

def updateRank(rank1, rank2, movieTitle):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()

    a = float(rank1)
    b = float(rank2)
    if a < 0.0 :
        return [("status",),("ERROR",)]   
    if a > 10.0 :
        return [("status",),("ERROR",)]   
    if b < 0.0 :
        return [("status",),("ERROR",)]   
    if b > 10.0 :
        return [("status",),("ERROR",)]   
    # Check if ranks are within wanted parameters
    cmd = "select count(m.movie_id) from movie m where m.title = %s"  
    cur.execute(cmd, (movieTitle,)) 
    for j in cur:
        print j
    if j == (0L,) or j > (1L,) :
        return [("status",),("ERROR",)]   
    # Check if there is only one movie with the title given
    cmd = "select m.rank from movie m where m.title = %s" 
    cur.execute(cmd, (movieTitle,)) 
    for k in cur:
        print k  
    if k == (None,):
        mo = (a+b)/2
    # If movie has no rank find average of rank1 and rank2
    else :
        c = float(k[0])
        mo = (a+b+c)/3
    # If movie has rank find average of rank1 and rank2 and the rank of the movie
    cmd = "update movie set rank = %s where movie.title = %s" 
    cur.execute(cmd, (mo, movieTitle,))  

    print rank1, rank2, movieTitle
    con.commit()
    cur.close()
    con.close()
    return [("status",),("OK",)]


def colleaguesOfColleagues(actorId1, actorId2):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()
    
    print actorId1, actorId2
    cmd = '''select mcd.title as movieTitle, c.actor_id as colleagueOfActor1, d.actor_id as colleagueOfActor2, a.actor_id as actor1, b.actor_id as actor2
       from actor a, actor b, actor c, actor d, role ra, role rb,  role rc,  role rd, role rcd,  role rdc, movie mac, movie mbd, movie mcd
       where a.actor_id = ra.actor_id
       and ra.movie_id = mac.movie_id
       and mac.movie_id = rc.movie_id
       and rc.actor_id = c.actor_id
       # actor a plays in a movie with actor c
       and b.actor_id = rb.actor_id
       and mbd.movie_id = rb.movie_id
       and d.actor_id = rd.actor_id
       and mbd.movie_id = rd.movie_id
       # actor b plays in a movie with actor b
       and c.actor_id = rcd.actor_id
       and rcd.movie_id = mcd.movie_id
       and d.actor_id = rdc.actor_id
       and rdc.movie_id = mcd.movie_id
       # actor c plays in a movie with actor d
       and a.actor_id != c.actor_id
       and a.actor_id != d.actor_id
       and b.actor_id != c.actor_id
       and b.actor_id != d.actor_id
       and c.actor_id != d.actor_id
       # actor a, b, c, d are different to actors
       and a.actor_id = %s
       and b.actor_id = %s'''
    cur.execute(cmd,(actorId1,actorId2,))  
    results = []
    results.append(("movieTitle", "colleagueOfActor1", "colleagueOfActor2", "actor1","actor2",),)
    for k in cur:
        temp = []
        temp.append(k[0])
        temp.append(k[1])
        temp.append(k[2])
        temp.append(k[3])
        temp.append(k[4])
        results.append(tuple(temp))
    cur.close()
    con.close()
    return results

def actorPairs(actorId):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()
	
    print actorId
    cmd = '''select distinct a1.actor_id
                from actor a1, actor a2
                where (select count(distinct g1.genre_id)
                           from movie m1, role r1,movie_has_genre mhg1, genre g1
                           where m1.movie_id = mhg1.movie_id and mhg1.genre_id = g1.genre_id and a1.actor_id = r1.actor_id and r1.movie_id = m1.movie_id)
	               + (select count(distinct g2.genre_id)
                           from movie m2, role r2,movie_has_genre mhg2, genre g2
		           where m2.movie_id = mhg2.movie_id and mhg2.genre_id = g2.genre_id and a2.actor_id = r2.actor_id and r2.movie_id = m2.movie_id) >=7

                      and a2.actor_id != a1.actor_id
                      and a2.actor_id = %s
                order by (a1.actor_id)'''
    cur.execute(cmd, (actorId,))
    # Find actors with compined played genres >= 7
    actors = []
    for i in cur:
        temp = []
        temp.append(i[0])
        actors.append(tuple(temp))
    cmd = '''select distinct g.genre_name
                from actor a1, movie m, role r, movie_has_genre mhg, genre g
                where a1.actor_id = %s
                          and a1.actor_id = r.actor_id and r.movie_id = m.movie_id and m.movie_id = mhg.movie_id and mhg.genre_id = g.genre_id
                order by (g.genre_name)'''
    cur.execute(cmd, (actorId,))
    # Find the name of the genre(s) for the given actor
    a1_genres = []
    for j in cur:
        temp = []
        temp.append(j[0])
        a1_genres.append(tuple(temp))

    count = 0
    logic = 0
    pairs = []
    pairs.append(("actor2Id",),)
    for a2 in actors :
        cmd = '''select distinct g.genre_name
                from actor a1, movie m, role r, movie_has_genre mhg, genre g
                where a1.actor_id = %s
                          and a1.actor_id = r.actor_id and r.movie_id = m.movie_id and m.movie_id = mhg.movie_id and mhg.genre_id = g.genre_id
                order by (g.genre_name)'''
        cur.execute(cmd, (a2,))
    # Find the name of the genre(s) for the actor(s) found before
        a2_genres = []
        for j in cur:
            temp = []
            temp.append(j[0])
            a2_genres.append(tuple(temp))
        for k in a1_genres:
            for kk in a2_genres:
                if k == kk:
                   logic = 1
                   break
        if logic == 0:
            pairs.append(tuple(a2))
            count = count + 1
        logic = 0
    # Find if the actor's pairs have played in different genre(s)
    cur.close()
    con.close()
    return pairs
	
def selectTopNactors(n):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()
    
    print n
    ending = int(n)
    cmd = '''select distinct g.genre_id
                from genre g'''
    cur.execute(cmd)
    genres_ids = []
    for t in cur:
        temp = []
        temp.append(t[0])
        genres_ids.append(tuple(temp))
    # Find every different genre
    results = []
    results.append(("genreName", "actorId", "numberOfMovies"),)
    for i in genres_ids:
        cmd = '''select distinct g.genre_name, a.actor_id, 
                    (select count(distinct movie.movie_id)
                     from movie, role , movie_has_genre mhg
                     where a.actor_id = role.actor_id and role.movie_id = movie.movie_id and movie.movie_id = mhg.movie_id and mhg.genre_id = g.genre_id
                     having count(distinct movie.movie_id)) as count
                    from actor a, genre g, movie m, role r, movie_has_genre mhgen
                    where a.actor_id = r.actor_id and r.movie_id = m.movie_id and m.movie_id = mhgen.movie_id and mhgen.genre_id = g.genre_id and g.genre_id = %s
                    group by (a.actor_id)
                    order by (count) Desc'''
        cur.execute(cmd, (i[0],))
    # For every genre find the N top actors
        count = 0
        for j in cur:
            temp = []
            if count == ending:
                break
            temp.append(j[0])
            temp.append(j[1])
            temp.append(j[2])
            results.append(tuple(temp))
            count = count + 1
    cur.close()
    con.close()
    return results

def traceActorInfluence(actorId):
    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()
    
    print actorId
    blacklist = []
    results = []
    results.append(tuple(("influencedActorId",),))
    cmd = '''select distinct ia.actor_id, g.genre_id, im.year
                from actor ia, actor a, role r, role ir, role ir1, movie_has_genre mhg, movie_has_genre imhg, movie m, movie im, genre g
                where a.actor_id = r.actor_id and r.movie_id = m.movie_id and ia.actor_id = ir.actor_id and ir.movie_id = m.movie_id

                         and ia.actor_id = ir1.actor_id and ir1.movie_id = im.movie_id and im.year > m.year

                         and m.movie_id = mhg.movie_id and mhg.genre_id = g.genre_id and im.movie_id = imhg.movie_id and imhg.genre_id = g.genre_id

                         and a.actor_id != ia.actor_id and a.actor_id = %s
                order by (ia.actor_id)'''
    cur.execute(cmd, (actorId,))
    # Find influenced actor(s) by the given actor
    l = 0
    for i in cur:
        temp = []
        temp.append(i[0])
        tempb = []
        tempb.append(i[0])
        if l == 1:
            if i[0] != t:
                results.append(tuple(temp))
        else :
            results.append(tuple(temp))
            l = 1
        # If we haven't took the first element ( l = 0 ), then hold the element to t
        t = i[0]
        tempb.append(i[1])
        tempb.append(i[2])
        blacklist.append(tempb)
    for b in blacklist:
        traceInfluence(b, blacklist, actorId, results)
    # For every actor in blacklist find his influences
    cur.close()
    con.close()
    return results

def traceInfluence(b, blacklist, actorId, results):
    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()

    y_year = int(b[2])
    g_gen = int(b[1])
    a_id = int(b[0])
    cmd = '''select distinct ia.actor_id, g.genre_id, im.year
                from actor ia, actor a, role r, role ir, role ir1, movie_has_genre mhg, movie_has_genre imhg, movie m, movie im, genre g
                where a.actor_id = r.actor_id and r.movie_id = m.movie_id and ia.actor_id = ir.actor_id and ir.movie_id = m.movie_id

                         and ia.actor_id = ir1.actor_id and ir1.movie_id = im.movie_id and im.year > m.year

                         and m.movie_id = mhg.movie_id and mhg.genre_id = g.genre_id and im.movie_id = imhg.movie_id and imhg.genre_id = g.genre_id
                         and g.genre_id = %s and m.year = %s

                         and a.actor_id != ia.actor_id and a.actor_id = %s and a.actor_id != %s and ia.actor_id != %s
                order by (ia.actor_id)'''
    cur.execute(cmd, (g_gen, y_year, a_id, actorId, actorId,))
    # Find influenced actor(s) by the given actor b
    for i in cur:
        l = 0
        temp = []
        temp.append(i[0])
        tempb = []
        tempb.append(i[0])
        first = 0
        for r in results :
            r_clear = r[0]
            if first == 1 :
                if i[0] == r_clear :
                    l = 1
            first = 1
    # if first == 1 is used to avoid comparison of the first element of results which is "influencedActorId"
        if l == 0 :
            results.append(tuple(temp))
    # If the actor found isn't in results, then add him
        tempb.append(i[1])
        tempb.append(i[2])
        blacklist.append(tempb)

