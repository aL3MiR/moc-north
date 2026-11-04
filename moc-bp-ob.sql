-- منصة المسارات الوطنية — ربط مساري الضغط والسمنة
-- السجل المدني المدخل في أحد المسارين يُحتسب في المسارين معاً (بعد تدقيقه «مطابق»).
-- السجل نفسه إذا أُدخل في المسارين يُحسب مرة واحدة فقط في كل مسار (خلال السنة نفسها)،
-- ويُعتمد له السجل «المطابق» إن وُجد، وإلا الأقدم.
-- الصق الملف كاملاً في Supabase > SQL Editor ثم اضغط Run (آمن لإعادة التشغيل، ولا يغيّر أي سجل).
create or replace view public.moc_counts as
  with others as (
    select center, pathway, day, audit, mawid, platform, raqeem
    from public.moc_records where pathway not in ('bp','ob')
  ), bpob as (
    select distinct on (center, nid, extract(year from day)) center, day, audit, mawid, platform, raqeem
    from public.moc_records where pathway in ('bp','ob')
    order by center, nid, extract(year from day), (audit = 'match') desc nulls last, (audit is null) asc, created_at
  ), merged as (
    select center, pathway, day, audit, mawid, platform, raqeem from others
    union all
    select b.center, v.p, b.day, b.audit, b.mawid, b.platform, b.raqeem from bpob b cross join (values ('bp'), ('ob')) as v(p)
  )
  select center, pathway, day,
    count(*)::int as n,
    (count(*) filter (where audit = 'match'))::int as matched,
    (count(*) filter (where audit is not null and audit <> 'match'))::int as unmatched,
    (count(*) filter (where audit is null))::int as pending,
    (count(*) filter (where mawid and platform and raqeem))::int as complete
  from merged
  group by center, pathway, day;
grant select on public.moc_counts to anon, authenticated;
notify pgrst, 'reload schema';
select 'تم: مسارا الضغط والسمنة مرتبطان في الاحتساب' as "النتيجة";
