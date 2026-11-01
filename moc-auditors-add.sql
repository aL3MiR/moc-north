-- منصة المسارات الوطنية — إضافة حسابين لفريق التدقيق: maeahmed و lmohammd
-- الصق الملف كاملاً في Supabase > SQL Editor ثم اضغط Run.
-- في الأسفل يظهر جدول بكلمة مرور كل حساب (تظهر مرة واحدة فقط) — انسخها وسلّمها لصاحبها، ثم امسح المحرر.
-- آمن لإعادة التشغيل: لا يغيّر كلمة مرور حساب موجود، ولا يمس الحسابات الأخرى.

create temp table if not exists moc_audit_creds(username text, password text);
truncate moc_audit_creds;
do $$
declare
  users text[] := array['maeahmed','lmohammd'];
  alpha text := 'abcdefghjkmnpqrstuvwxyz23456789';
  i int; j int; em text; pw text; uid uuid;
begin
  for i in 1..array_length(users,1) loop
    em := lower(users[i])||'@audit.sh-north.example';
    if exists (select 1 from auth.users where email = em) then
      insert into moc_audit_creds values (users[i], '(موجود مسبقاً - لم تتغير)');
      continue;
    end if;
    pw := '';
    for j in 1..10 loop
      pw := pw || substr(alpha, (get_byte(extensions.gen_random_bytes(1),0) % length(alpha))+1, 1);
    end loop;
    uid := gen_random_uuid();
    insert into auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
        raw_app_meta_data,raw_user_meta_data,created_at,updated_at,
        confirmation_token,recovery_token,email_change_token_new,email_change)
      values ('00000000-0000-0000-0000-000000000000',uid,'authenticated','authenticated',em,
        extensions.crypt(pw, extensions.gen_salt('bf')),now(),
        jsonb_build_object('provider','email','providers',jsonb_build_array('email'),'role','moc_auditor'),
        jsonb_build_object('username',users[i]),now(),now(),'','','','');
    insert into auth.identities (id,user_id,provider_id,identity_data,provider,last_sign_in_at,created_at,updated_at)
      values (gen_random_uuid(),uid,uid::text,jsonb_build_object('sub',uid::text,'email',em,'email_verified',true),'email',now(),now(),now());
    insert into moc_audit_creds values (users[i], pw);
  end loop;
end $$;

select username as "اسم المستخدم", password as "كلمة المرور" from moc_audit_creds order by username;
