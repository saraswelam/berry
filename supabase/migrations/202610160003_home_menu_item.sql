insert into public.categories(name,slug,display_order,is_visible)
values ('Home','home',0,true)
on conflict (slug) do update set name='Home', display_order=0, is_visible=true;

update public.categories
set display_order = case slug
  when 'analog' then 1
  when 'headshots' then 2
  when 'commercial' then 3
  when 'nature' then 4
  when 'around-the-world' then 5
  when 'biography' then 6
  when 'contact-information' then 7
  else display_order
end
where slug in ('analog','headshots','commercial','nature','around-the-world','biography','contact-information');
