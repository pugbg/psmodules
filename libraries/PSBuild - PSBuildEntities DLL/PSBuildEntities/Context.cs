using System.Collections.ObjectModel;
using System;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;

namespace PSBuild
{
    public sealed class Context
    {
        #region Singleton Implementation
        private static readonly Context instance = new Context();

        static Context()
        {
        }

        private Context()
        {
            CommandsToModuleMapping = new CommandInfoCollection();
            SolutionModulesCache = new PSModuleValidationCollection();
            SolutionScriptsCache = new PSScriptValidationCollection();
            PsGetModuleValidationCache = new PSRepositoryItemValidationCollection();
            AssertedPSRepositories = new List<string>();
            BuiltModulesCache = new PSModuleBuildInfoCollection();
            BuiltScriptsCache = new PSScriptBuildInfoCollection();
            ExternalModulesCache = new PSModuleBuildInfoCollection();
            CheckCommandReferencesConfiguration = new CheckCommandReferencesConfiguration();
        }

        public static Context Current
        {
            get
            {
                return instance;
            }
        }
        #endregion

        public bool AllowDuplicateCommandsInCommandToModuleMapping { get; set; }
        public bool UpdateModuleReferences { get; set; }

        public CommandInfoCollection CommandsToModuleMapping { get; set; }
        public PSModuleValidationCollection SolutionModulesCache { get; set; }
        public PSScriptValidationCollection SolutionScriptsCache { get; set; }
        public PSRepositoryItemValidationCollection PsGetModuleValidationCache { get; set; }
        public List<string> AssertedPSRepositories { get; set; }

        public PSModuleBuildInfoCollection BuiltModulesCache { get; set; }
        public PSModuleBuildInfoCollection ExternalModulesCache { get; set; }
        public PSScriptBuildInfoCollection BuiltScriptsCache { get; set; }

        public CheckCommandReferencesConfiguration CheckCommandReferencesConfiguration { get; set; }
    }
}