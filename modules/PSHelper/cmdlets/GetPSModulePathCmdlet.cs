using System;
using System.Management.Automation;

namespace pugbg.modules.loghelper
{
    [Cmdlet("Get", "PSModulePath")]
    [OutputType(typeof(string[]))]
    public class GetPSModulePathCmdlet : Cmdlet
    {
        #region Parameters

        //Parameter Scope
        [Parameter(Mandatory = false)]
        public EnvironmentVariableTarget[] Scope { get; set; } = { EnvironmentVariableTarget.Machine };

        #endregion

        #region Execution

        protected override void ProcessRecord()
        {
            foreach (var scp in Scope)
            {
                var r = Environment.GetEnvironmentVariable("PsModulePath", scp);
                if (!String.IsNullOrEmpty(r))
                {
                    WriteObject(r.Split(";".ToCharArray()), true);
                }
            }
        }

        #endregion
    }
}
