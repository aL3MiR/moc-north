-- منصة المسارات الوطنية — من أضاف الحالات الإيجابية؟ (قراءة فقط، لا يغيّر شيئاً)
-- الصقه في Supabase > SQL Editor ثم Run.
select p.center as "المركز", p.result_date as "تاريخ النتيجة", p.created_at as "تاريخ الإضافة",
       u.email as "الحساب الذي أضافها", u.raw_app_meta_data->>'role' as "صلاحيته"
from public.moc_positive p
left join auth.users u on u.id = p.created_by
order by p.created_at;
