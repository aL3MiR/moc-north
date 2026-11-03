-- منصة المسارات الوطنية — مدير المركز يضيف الحالات الإيجابية لمركزه ويتابع خطواتها
-- الصق الملف كاملاً في Supabase > SQL Editor ثم اضغط Run (آمن لإعادة التشغيل).
-- فريق القطاع (المشرف والتدقيق): إضافة وتعديل وحذف لكل المراكز كما كان.
-- مدير المركز: إضافة وتعديل لحالات مركزه فقط، بدون حذف.
drop policy if exists moc_pos_write on public.moc_positive;
drop policy if exists moc_pos_ins on public.moc_positive;
drop policy if exists moc_pos_upd on public.moc_positive;
drop policy if exists moc_pos_del on public.moc_positive;

create policy moc_pos_ins on public.moc_positive for insert to authenticated
  with check (public.moc_role() in ('owner','moc_auditor','moc_coordinator')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()));

create policy moc_pos_upd on public.moc_positive for update to authenticated
  using (public.moc_role() in ('owner','moc_auditor','moc_coordinator')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()))
  with check (public.moc_role() in ('owner','moc_auditor','moc_coordinator')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()));

create policy moc_pos_del on public.moc_positive for delete to authenticated
  using (public.moc_role() in ('owner','moc_auditor','moc_coordinator'));

notify pgrst, 'reload schema';
select 'تم: مدير المركز يضيف ويتابع حالات مركزه، والحذف لفريق القطاع' as "النتيجة";
