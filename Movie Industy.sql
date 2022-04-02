use imdblinked

/*question 1.1a*/

/* Write a query that returns a resultset with two fields – the moviekey and a field called Budget which has the budget for 
that movie.  Restrict your results to US Dollars and non-zero records.  Exclude any movie with multiple entries after those 
conditions have been applied.*/

select t.MovieKey, (b.amount) as Budget
from (    
    select MovieKey, count(amount) as [occurance]
    from Business 
    where currency = 'USD' and code = 'BT' and amount > 0
    group by MovieKey
    Having count(amount) = 1 
) as t 
join (
    select MovieKey, amount 
    from Business 
    where currency = 'USD' and code = 'BT' and amount > 0 
)as b on t.MovieKey = b.MovieKey
order by (b.amount) DESC


/*How many movies have duplicate budget records */

select MovieKey, count(amount) as [occurance]
from Business 
where currency = 'USD' and code = 'BT' and amount > 0
group by MovieKey
Having count(amount) > 1 

/*The number of rows affected by the query above is 791, meaning that there is 791 duplicate budget records*/

/* Retrive the Gross Revenue of Movies as a table*/
DROP TABLE IF EXISTS #GROSS_He 

select (case when d.moviekey is null then w.movieKey else d.movieKey end) as MovieKey, d.[DomGross], w.[WWGross]
into #GROSS_He
from (
        select distinct MovieKey, max(amount) as [DomGross]
        from Business
        where currency = 'USD' and country = 'USA' and code = 'GR'
        group by MovieKey
    ) as d 
FULL OUTER JOIN (
        select distinct MovieKey, max(amount) as [WWGross]
        from Business
        where currency = 'USD' and country = 'Worldwide' and code = 'GR'
        group by MovieKey
) as w on d.MovieKey = w.MovieKey 
go

select *
from #GROSS_He


/* 10 highest grossing movies worldwide of all time */
select top 10(g.[WWGross]), m.primaryName
from #GROSS_He as g
Join MovieMaster as m on g.movieKey = m.movieKey
order by g.[WWGross] DESC

/* computes the fraction of box office which is earned domestically */
select b.date, sum (DomGross) / (sum (WWGross)) as [Fraction of GR Earned Domestically]
from #GROSS_He 
Join MovieMaster as b on b.MovieKey = #GROSS_He.MovieKey
Where b.date BETWEEN 1997 AND 2016
group by b.date
order by b.date asc


/* top 5 movies by ROI */
DROP TABLE IF EXISTS #Budget_after1990
select t.MovieKey, (b.budget) as Budget
into #Budget_after1990
from (    
    select MovieKey, count(amount) as [occurance]
    from Business 
    where currency = 'USD' and code = 'BT' and amount > 0
    group by MovieKey
    Having count(amount) = 1 
) as t 
join (
    select MovieKey, avg(amount) as budget 
    from Business 
    where currency = 'USD' and code = 'BT' and amount > 0 
    group by movieKey
)as b on t.MovieKey = b.MovieKey
order by (b.budget) DESC

DROP TABLE IF EXISTS #GROSS_after1900 
select (case when d.MovieKey is NULL then w.MovieKey else d.MovieKey end) as MovieKey, 
        d.[DomGross] as [DomGross], w.[WWGross] as [WWGross]
Into #GROSS_after1900 
from (
        select MovieKey, max(amount) as [DomGross]
        from Business
        where currency = 'USD' and country = 'USA' and code = 'GR' 
        group by MovieKey
    ) as d 
FULL JOIN (
        select MovieKey, max(amount) as [WWGross]
        from Business
        where currency = 'USD' and country = 'Worldwide' and code = 'GR'
        group by MovieKey
) as w on d.MovieKey = w.MovieKey 
Where ([DomGross] Is NOT NULL OR [WWGross] is NOT NULL)
go

/* The complete Query*/
select distinct bt.MovieKey, m.primaryName, bt.Budget, gr.[DomGross] as [Domestic GR], 
(case when bt.budget = 0 then NULL else (gr.DomGross/bt.budget) end) as ROI
from #Budget_after1990 as bt
join #GROSS_after1900 as gr on bt.movieKey = gr.movieKey
join mpaa on mpaa.moviekey = bt.moviekey
join MovieMaster as m on m.moviekey = bt.movieKey
where m.date >= 1990
Order by ROI desc




