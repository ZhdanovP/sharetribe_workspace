# sharetribe_workspace

You need to install docker on local machine

1. Change line in docker-compose.yml

`../../sharetribe:/home/developer/sharetribe`

2. Specify path to sharetribe project insead of `../../sharetribe`

3. Run `docker-compose up`

4. After your docker will be running open second terminal and exectute command

` docker exec -it sharetribe_workspace_development_1 bash `

For enter inside the container. 

5. Run `cd /home/developer/sharetribe ` inside container
