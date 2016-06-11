heroku pg:backups capture --app storystorm
curl -o db/db.dump `heroku pg:backups --app storystorm public-url`
pg_restore -d storystorm db/db.dump
