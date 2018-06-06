# samlapi

## Usage

You can use PSU WebAccess login for both API and CLI access to AWS.  
I've tested this lightly so far by building the docker image locally, then running.

I ran it by running the following command in the root of this repository:

```bash
docker run -it --rm -v ~/.aws:/root/.aws $(docker build -q .)
```

AFAIK, we don't have a PSU docker image repository for me to publish this. For now, it'll remain as source only.

After this command has been run it will prompt you for your accessID and password.  This will be used to login you into PSU WebAccess. You will get a push from DUO.  Once you have confirmed the DUO notification, you will be prompted to select the role you wish to use for login, if you have only one role it will choose that automatically.  The credentials will be placed in the default credential file (~/.aws/credentials) and can be used as follows:

```bash
aws --profile saml s3 ls
```

## Credit & More Info

Credit where credit is due:

http://blogs.cornell.edu/cloudification/2016/07/05/using-shibboleth-for-aws-api-and-cli-access/

Base Image can be found here: https://github.com/CU-CommunityApps/docker-xvfb-firefox.
