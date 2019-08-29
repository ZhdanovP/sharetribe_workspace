# sharetribe_workspace

You need to install docker on local machine

Change line in docker-compose.yml

`../../sharetribe:/home/developer/sharetribe`

Specify path to sharetribe project insead of `../../sharetribe`

Run `docker-compose up`

After your docker will be running open second terminal and exectute command

` docker exec -it sharetribe_workspace_development_1 bash `

For enter inside the container. Run `cd /home/developer/sharetribe ` inside container
