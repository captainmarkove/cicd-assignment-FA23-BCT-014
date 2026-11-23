#!/bin/bash
# Installs Docker + Jenkins on a fresh Ubuntu EC2 server and creates the pipeline job.
set -x
export DEBIAN_FRONTEND=noninteractive
REPO_URL="https://github.com/captainmarkove/cicd-assignment-FA23-BCT-014.git"

apt-get update
apt-get install -y docker.io git curl fontconfig
apt-get install -y openjdk-21-jre-headless || apt-get install -y default-jre-headless
systemctl enable --now docker

useradd -m -d /var/lib/jenkins -s /bin/bash jenkins
usermod -aG docker jenkins
mkdir -p /opt/jenkins /var/lib/jenkins/init.groovy.d /var/lib/jenkins/jobs/cicd-pipeline
curl -fsSL -o /opt/jenkins/jenkins.war https://get.jenkins.io/war-stable/latest/jenkins.war

PM_URL=$(curl -s https://api.github.com/repos/jenkinsci/plugin-installation-manager-tool/releases/latest | grep browser_download_url | grep '\.jar"' | head -1 | cut -d'"' -f4)
curl -fsSL -o /opt/jenkins/pm.jar "$PM_URL"
java -jar /opt/jenkins/pm.jar --war /opt/jenkins/jenkins.war --plugin-download-directory /var/lib/jenkins/plugins \
  --plugins git workflow-aggregator github pipeline-stage-view junit

ADMIN_PW=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)
echo "$ADMIN_PW" > /root/jenkins-admin-password.txt
chmod 600 /root/jenkins-admin-password.txt

cat > /var/lib/jenkins/jobs/cicd-pipeline/config.xml <<XML
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>CI/CD pipeline for cicd-assignment-FA23-BCT-014</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs><hudson.plugins.git.UserRemoteConfig><url>${REPO_URL}</url></hudson.plugins.git.UserRemoteConfig></userRemoteConfigs>
      <branches><hudson.plugins.git.BranchSpec><name>*/main</name></hudson.plugins.git.BranchSpec></branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
XML

cat > /var/lib/jenkins/init.groovy.d/init.groovy <<GROOVY
import jenkins.model.*
import hudson.security.*
def j = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
realm.createAccount("admin", "${ADMIN_PW}")
j.setSecurityRealm(realm)
def st = new FullControlOnceLoggedInAuthorizationStrategy()
st.setAllowAnonymousRead(true)
j.setAuthorizationStrategy(st)
j.save()
def job = j.getItem("cicd-pipeline")
if (job != null && job.getLastBuild() == null) {
  Thread.start { sleep(45000); job.scheduleBuild2(0) }
}
GROOVY

chown -R jenkins:jenkins /var/lib/jenkins /opt/jenkins

cat > /etc/systemd/system/jenkins.service <<UNIT
[Unit]
Description=Jenkins
After=network.target docker.service

[Service]
User=jenkins
Environment=JENKINS_HOME=/var/lib/jenkins
ExecStart=/usr/bin/java -Djenkins.install.runSetupWizard=false -jar /opt/jenkins/jenkins.war --httpPort=8080
Restart=always

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now jenkins
echo "SETUP DONE"
