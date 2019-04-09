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
        //Parameter Path
        [Parameter(Mandatory = true)]
        public String[] Path { get; set; }

        //Parameter Force
        [Parameter(Mandatory = false)]
        public SwitchParameter Force { get; set; }

        //Parameter Scope
        [Parameter(Mandatory = false)]
        public EnvironmentVariableTarget[] Scope { get; set; } = { EnvironmentVariableTarget.Machine };

        protected override void ProcessRecord()
        {
            SetPSModulePath.Execute(path: this.Path.ToList(), force: this.Force.IsPresent, scope: this.Scope.ToList());
        }
    }

    internal class SetPSModulePath
    {
        internal static void Execute(IEnumerable<String> path, bool force, IEnumerable<EnvironmentVariableTarget> scope)
        {
            if (!force)
            {
                foreach (var p in path)
                {
                    if (!Directory.Exists(p))
                    {
                        throw new DirectoryNotFoundException($"Path {p} does not exists");
                    }
                }
            }

            foreach (var scp in scope)
            {
                Environment.SetEnvironmentVariable("PsModulePath", String.Join(";", path), scp);
            }
        }
    }
}
