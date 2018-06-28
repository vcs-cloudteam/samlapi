# samlapi

[![Docker Repository on Quay](https://quay.io/repository/pennstate/aws-saml-login/status "Docker Repository on Quay")](https://quay.io/repository/pennstate/aws-saml-login)

## Usage

You can use PSU WebAccess login for both API and CLI access to AWS.  

```bash
docker run -it --rm -v ~/.aws:/root/.aws quay.io/pennstate/aws-saml-login
```

After this command has been run it will prompt you for your accessID and password.  This will be used to login you into PSU WebAccess. You will get a push from DUO.  Once you have confirmed the DUO notification, you will be prompted to select the role you wish to use for login, if you have only one role it will choose that automatically.  The credentials will be placed in the default credential file (~/.aws/credentials) and can be used as follows:

```bash
aws --profile saml <subcommand>
```

## Credit & More Info

Credit where credit is due:

http://blogs.cornell.edu/cloudification/2016/07/05/using-shibboleth-for-aws-api-and-cli-access/

Base Image can be found here: https://github.com/CU-CommunityApps/docker-xvfb-firefox.
