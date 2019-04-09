using System;
using System.Management.Automation;
using System.Linq;
using System.Collections.Generic;

namespace pugbg.modules.loghelper
{
    [Cmdlet("Get", "PSModulePath")]
    [OutputType(typeof(string[]))]
    public class GetPSModulePathCmdlet : Cmdlet
    {
        //Parameter Scope
        [Parameter(Mandatory = false)]
        public EnvironmentVariableTarget[] Scope { get; set; } = { EnvironmentVariableTarget.Machine };

        protected override void ProcessRecord()
        {
            WriteObject(GetPSModulePath.Execute(scope: this.Scope.ToList()), true);
        }
    }

    internal class GetPSModulePath
    {
        internal static List<string> Execute(IEnumerable<EnvironmentVariableTarget> scope)
        {
            var result = new List<string>();
            foreach (var scp in scope)
            {
                var r = Environment.GetEnvironmentVariable("PsModulePath", scp);
                if (!String.IsNullOrEmpty(r))
                {
                    foreach (var e in r.Split(";".ToCharArray()))
                    {
                        result.Add(e);
                    }
                }
            }

            return result;
        }
    }
}
