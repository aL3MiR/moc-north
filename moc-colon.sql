-- منصة المسارات الوطنية — صحة القولون: المؤشر الشهري والحالات الإيجابية
-- الصق هذا الملف كاملاً في Supabase > SQL Editor ثم اضغط Run (مرة واحدة). آمن لإعادة التشغيل.

-- 1) المؤشر الأول: رصيد شهر أكتوبر حتى 2026-10-21 (طلبات التحاليل والنتائج المكتملة لكل مركز)
update public.moc_config
  set data = jsonb_set(data, '{colBase}', $cb${"month": "2026-10", "date": "2026-10-21", "c": {"c01": {"req": 11, "res": 11}, "c02": {"req": 9, "res": 9}, "c03": {"req": 8, "res": 8}, "c04": {"req": 0, "res": 0}, "c05": {"req": 4, "res": 4}, "c06": {"req": 8, "res": 8}, "c07": {"req": 10, "res": 10}, "c08": {"req": 6, "res": 6}, "c09": {"req": 4, "res": 4}, "c10": {"req": 5, "res": 5}, "c11": {"req": 9, "res": 9}, "c12": {"req": 2, "res": 2}, "c13": {"req": 5, "res": 5}, "c14": {"req": 12, "res": 12}, "c15": {"req": 2, "res": 2}, "c16": {"req": 24, "res": 24}, "c17": {"req": 9, "res": 9}, "c18": {"req": 15, "res": 15}, "c19": {"req": 3, "res": 3}, "c20": {"req": 4, "res": 4}, "c21": {"req": 3, "res": 3}, "c22": {"req": 5, "res": 5}, "c23": {"req": 3, "res": 3}, "c24": {"req": 0, "res": 0}}}$cb$::jsonb, true), updated_at = now()
  where id = 'main';

-- 2) المؤشر الثاني: الحالات الإيجابية (جدول مقفل: لا يقرؤه الزوار)
create table if not exists public.moc_positive (
  id uuid primary key default gen_random_uuid(),
  center text not null,
  nid text not null check (nid ~ '^[12][0-9]{9}$'),
  phone text check (phone is null or phone ~ '^05[0-9]{8}$'),
  result_date date not null,
  informed boolean,
  decision text check (decision is null or decision in ('accept','refuse')),
  consent_doc boolean,
  raqeem_refusal boolean,
  educator boolean,
  edu_result text check (edu_result is null or edu_result in ('accept','refuse')),
  recontact_date date,
  recontact_result text check (recontact_result is null or recontact_result in ('accept','refuse')),
  consent_form boolean,
  refusal_form boolean,
  hospital boolean,
  platform boolean,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create index if not exists moc_positive_center on public.moc_positive (center, result_date);
alter table public.moc_positive enable row level security;

-- القراءة: فريق القطاع (المشرف وحسابات التدقيق) للكل، ومدير المركز لحالات مركزه فقط
drop policy if exists moc_pos_read on public.moc_positive;
create policy moc_pos_read on public.moc_positive for select to authenticated
  using (public.moc_role() in ('owner','moc_auditor','moc_coordinator')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()));
-- الإضافة والتعديل والحذف: فريق القطاع فقط
drop policy if exists moc_pos_write on public.moc_positive;
create policy moc_pos_write on public.moc_positive for all to authenticated
  using (public.moc_role() in ('owner','moc_auditor','moc_coordinator'))
  with check (public.moc_role() in ('owner','moc_auditor','moc_coordinator'));

create or replace function public.moc_pos_touch() returns trigger language plpgsql as $$
begin
  new.updated_at := now(); new.updated_by := auth.uid();
  if tg_op = 'INSERT' then new.created_by := auth.uid(); end if;
  return new;
end $$;
drop trigger if exists moc_pos_touch on public.moc_positive;
create trigger moc_pos_touch before insert or update on public.moc_positive
  for each row execute function public.moc_pos_touch();

revoke all on public.moc_positive from anon;
grant select, insert, update, delete on public.moc_positive to authenticated;

-- أعداد عامة بدون بيانات شخصية
create or replace view public.moc_pos_counts as
  select center,
    count(*)::int as n,
    (count(*) filter (where hospital))::int as referred,
    (count(*) filter (where refusal_form and not coalesce(hospital,false)))::int as refused,
    (count(*) filter (where not coalesce(hospital,false) and not coalesce(refusal_form,false)))::int as open
  from public.moc_positive
  group by center;
grant select on public.moc_pos_counts to anon, authenticated;

notify pgrst, 'reload schema';
