using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Collections.Generic;

namespace pugbg.modules.loghelper
{
    [Cmdlet("Register", "LhConfiguration")]
    [OutputType(typeof(LhConfiguration))]
    public class RegisterLhConfigurationCmdlet : PSCmdlet
    {
        #region Parameters

        //Parameter ConfigurationDefinition
        [Parameter(Mandatory = true, ParameterSetName = "Definition")]
        public List<Dictionary<string, object>> ConfigurationDefinition { get; set; }

        //Parameter JsonConfigurationDefinition
        [Parameter(Mandatory = true, ParameterSetName = "JsonDefinition")]
        public List<string> JsonConfigurationDefinition { get; set; }

        //Parameter PsdConfigurationFilePath
        [Parameter(Mandatory = true, ParameterSetName = "PsdFile")]
        public List<string> PsdConfigurationFilePath { get; set; }

        //Parameter JsonConfigurationFilePath
        [Parameter(Mandatory = true, ParameterSetName = "JsonFile")]
        public List<string> JsonConfigurationFilePath { get; set; }

        #endregion

        #region Execution

        protected override void ProcessRecord()
        {
            //Initialize Configurations
            var configurations = new List<LhConfiguration>();
            switch (this.ParameterSetName)
            {
                case "Definition":
                    foreach (var cfd in this.ConfigurationDefinition)
                    {
                        configurations.Add(LhConfigurationFactory.Parse(cfd));
                    }
                    break;

                default:
                    throw new Exception($"Unsupported ParameterSetName: {this.ParameterSetName}");
            }

            //return result
            WriteObject(configurations);
        }

        #endregion
    }
}
