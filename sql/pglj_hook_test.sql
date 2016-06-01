show shared_preload_libraries;
create user badpass with password 'bad';
create user badpass with password 'better';
drop user badpass;
