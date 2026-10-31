-- منصة المسارات الوطنية — صلاحية الحذف لفريق القطاع
-- الصق هذا في Supabase > SQL Editor ثم Run. يسمح للمشرف وفريق التدقيق بحذف أي سجل مدني خاطئ،
-- ويبقى مدير المركز قادراً على حذف سجلات مركزه التي لم تُدقق بعد فقط.
drop policy if exists moc_rec_del on public.moc_records;
create policy moc_rec_del on public.moc_records for delete to authenticated
  using (public.moc_role() in ('owner','moc_auditor')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center() and audit is null));
notify pgrst, 'reload schema';
