git add .
 git commit -am "adding download plugins"
 git push heroku master
heroku run rake db:migrate
heroku logs -t

