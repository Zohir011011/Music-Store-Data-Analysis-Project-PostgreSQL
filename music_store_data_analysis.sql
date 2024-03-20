select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;

-----------------------------------------------
-----------------------------------------------
-- solving question
-- there are 3 sets of questions. we have to find the answers by quering.

-- 1st set is for easy questions.
-- q1: Who is the senior most employee based on job title ?
-- q2: Which countires have the most invoices ?
-- q3: What are top 3 values of total invoice ?
-- q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.
-- q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.

-- solution 1:
select *
from employee
where reports_to is null;

-- solution 2:
select billing_country, count(*)as total_invoices
from invoice
group by billing_country
order by total_invoices desc;

-- solution 3:
select total as top_values
from invoice
order by total desc
limit 3;

-- solution 4:
select billing_city, count(*) as total, sum(total) as total_invoice
from invoice
group by billing_city
order by total desc;

-- slution 5:
----------method 1: JOIN
select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total_spent
from customer 
join invoice 
on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total_spent desc;

----------method 2: COMMON TABLE EXPRESSION + JOIN
with cte as (
	select invoice. customer_id, customer.first_name, customer.last_name, invoice.total
	from customer 
	join invoice 
	on customer.customer_id = invoice.customer_id)
select customer_id, first_name, last_name, sum(total) as total_invoice
from cte
group by customer_id, first_name, last_name
order by total_invoice desc;



-- 2nd set is for moderate questions.
-- q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A
-- q2: Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands
-- q3: Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first 
-- q4: We want to find out the top 10 selling artist. Write a query to return the best selling artist ids, names and total sales from each artist.


-- solution 1:
-- method 1: NESTED QUERY
select email, first_name, last_name
from customer
where customer_id in (
				select customer_id 
				from invoice
				where invoice_id in (
							select invoice_id 
							from invoice_line 
							where track_id in (
										select track_id 
										from track 
										where genre_id = (
													select genre_id 
													from genre 
													where name = 'Rock'))))

order by email;

-- method 2: JOIN FUNCTION
select distinct c.email, c.first_name, c.last_name, g.name as genre
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on g.genre_id = t.genre_id
where g.name = 'Rock'
order by c.email;

-- solution 2:
select artist.name, count(*) as count
from artist 
join album on artist.artist_id = album.artist_id
join track on track.album_id = album.album_id
join genre on track.genre_id = genre.genre_id
where genre.name = 'Rock'
group by artist.name
order by count desc
limit 10;

-- solution 3:
select name, milliseconds 
from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;

-- solution 4:
select at.artist_id, at.name as artist_name, sum(il.unit_price * il.quantity) as total_spent
from invoice_line il
join track t on il.track_id = t.track_id
join album al on al.album_id = t.album_id
join artist at on at.artist_id = al.artist_id
group by 1
order by 3 desc
limit 10;


-- 3rd set is for hard questions
-- q1: Find how much amount spent by each customer on each artists? Write a query to return customer name, artist name and total spent
-- q2: Find how much amount spent by each customer on the best selling artist? Write a query to return the customer ids, customer names, best selling artist name and total spent by each customer
-- q3: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest total spent. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres 
-- q4: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres 
-- q5: Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount 


-- solution 1:
with ctable as (
	     select customer.customer_id, customer.first_name, customer.last_name, invoice_line.* from customer
	     join invoice on invoice.customer_id = customer.customer_id
	     join invoice_line on invoice_line.invoice_id = invoice.invoice_id
        ),
	 
	 atable as (
		 select track.album_id,track.track_id, album.album_id, album.artist_id, artist.* from track
		 join album on album.album_id = track.album_id
		 join artist on artist.artist_id = album.artist_id
	     )
select  ctable.first_name, ctable.last_name, atable.name, sum(ctable.unit_price * ctable.quantity) as total_spent
from ctable
join atable on ctable.track_id = atable.track_id
group by 1, 2, 3
order by 3;


-- solution 2:
with best_selling_artist as (
				select artist.artist_id, artist.name as artist_name, sum(invoice_line.unit_price * invoice_line.quantity) as total_spent
				from invoice_line
				join track on track.track_id = invoice_line.track_id
				join album on album.album_id = track.album_id
				join artist on artist.artist_id = album.artist_id
				group by 1
				order by 3 desc
				limit 1)

select c.customer_id, c.first_name, c.last_name, bts.artist_name, sum(il.unit_price * il.quantity) as amount_spent 
from customer c
join invoice i on i.customer_id = c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album a on a.album_id = t.album_id
join best_selling_artist bts on bts.artist_id = a.artist_id
group by 1, 2, 3, 4
order by 5 desc


-- solution 3:
with cte as (
		select i.billing_country as country, g.genre_id, g.name as genre,  sum(il.unit_price * il.quantity) as total_spent,
	    dense_rank() over(partition by i.billing_country order by sum(il.unit_price * il.quantity) desc) as top_genre
		from invoice i
		join invoice_line il on il.invoice_id = i.invoice_id
		join track t on t.track_id = il.track_id
		join genre g on g.genre_id = t.genre_id
		group by 1, 2, 3
		order by 1 )
select country, genre, total_spent
from cte
where top_genre = 1;


-- solution 4:
-- method 1: COMMON TABLE EXPRESSION + WINDOW FUNCION
with cte as (
		select i.billing_country as country, g.genre_id, g.name as genre,  count(il.quantity) as total_count,
	    dense_rank() over(partition by i.billing_country order by count(il.quantity) desc) as top_genre
		from invoice i
		join invoice_line il on il.invoice_id = i.invoice_id
		join track t on t.track_id = il.track_id
		join genre g on g.genre_id = t.genre_id
		group by 1, 2, 3
		order by 1)
select country, genre, total_count
from cte
where top_genre = 1;

-- method 2: RECURSIVE
with recursive sales_per_country as (
						select i.billing_country as country, g.genre_id, g.name as genre,  count(il.quantity) as total_count
						from invoice i
						join invoice_line il on il.invoice_id = i.invoice_id
						join track t on t.track_id = il.track_id
						join genre g on g.genre_id = t.genre_id
						group by 1, 2, 3
						order by 1),
			 max_genre_per_country as (
				        select country, max(total_count) as total_count
				        from sales_per_country
			            group by 1
			            order by 1)
select mgpc.country, spc.genre, mgpc.total_count
from max_genre_per_country mgpc
right join sales_per_country spc 
on spc.country = mgpc.country
where spc.total_count = mgpc.total_count


-- solution 5:
with cte as (
		select i.billing_country, c.customer_id, c.first_name, c.last_name, sum(i.total) as total_spent,
			   dense_rank() over(partition by i.billing_country order by sum(i.total) desc) as top_customer
		from customer c
		join invoice i on i.customer_id = c.customer_id
		group by 1, 2, 3, 4)
select billing_country, first_name, last_name, total_spent 
from cte
where top_customer = 1;














