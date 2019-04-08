using System;
using System.Management.Automation;
using System.Linq;
using System.Collections.Generic;
using System.IO;

namespace pugbg.modules.loghelper
{
    [Cmdlet("Set", "PSModulePath")]
    [OutputType(typeof(void))]
    public class SetPSModulePathCmdlet : Cmdlet
    {
        #region Parameters

        //Parameter Path
        [Parameter(Mandatory = true)]
        public String[] Path { get; set; }

        //Parameter Force
        [Parameter(Mandatory = false)]
        public SwitchParameter Force { get; set; }

        //Parameter Scope
        [Parameter(Mandatory = false)]
        public EnvironmentVariableTarget[] Scope { get; set; } = { EnvironmentVariableTarget.Machine };

        #endregion

        #region Execution

        protected override void ProcessRecord()
        {
            if (!Force.IsPresent)
            {
                foreach (var p in Path)
                {
                    if (!Directory.Exists(p))
                    {
                        throw new DirectoryNotFoundException($"Path {p} does not exists");
                    }
                }
            }

            foreach (var scp in Scope)
            {
                Environment.SetEnvironmentVariable("PsModulePath", String.Join(";", Path), scp);
            }
        }

        #endregion
    }
}
