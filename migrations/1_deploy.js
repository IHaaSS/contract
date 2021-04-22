var Incidents = artifacts.require("Incidents");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(Incidents);
};