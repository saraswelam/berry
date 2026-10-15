-- Reconcile the original starter menu for existing projects without removing
-- any category records or photographs. Legacy categories stay manageable in
-- the dashboard but are hidden from the public menu.
update public.categories set name='Analog', slug='analog', display_order=0, is_visible=true where slug='analog-photography';
update public.categories set name='Headshots', display_order=1, is_visible=true where slug='headshots';
update public.categories set name='Commercial', display_order=2, is_visible=true where slug='commercial';
update public.categories set name='Biography', display_order=5, is_visible=true where slug='biography';
update public.categories set name='Contact Information', slug='contact-information', display_order=6, is_visible=true where slug='contact';

insert into public.categories(name,slug,display_order,is_visible) values
  ('Nature','nature',3,true),
  ('Around the World','around-the-world',4,true)
on conflict (slug) do update set name=excluded.name, display_order=excluded.display_order, is_visible=true;

update public.categories
set is_visible=false
where slug in ('home','architecture','fine-art','artists');
