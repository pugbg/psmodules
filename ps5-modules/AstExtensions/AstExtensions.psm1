Function Get-AstStatement
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[System.Management.Automation.Language.Ast]$Ast,

		[Parameter(Mandatory=$false)]
		[ValidateSet(
			'StatementAst',
			'PipelineBaseAst',
			'ErrorStatementAst',
			'PipelineAst',
			'AssignmentStatementAst',
			'TypeDefinitionAst',
			'UsingStatementAst',
			'FunctionDefinitionAst',
			'IfStatementAst',
			'DataStatementAst',
			'LabeledStatementAst',
			'LoopStatementAst',
			'ForEachStatementAst',
			'ForStatementAst',
			'DoWhileStatementAst',
			'DoUntilStatementAst',
			'WhileStatementAst',
			'SwitchStatementAst',
			'TryStatementAst',
			'TrapStatementAst',
			'BreakStatementAst',
			'ContinueStatementAst',
			'ReturnStatementAst',
			'ExitStatementAst',
			'ThrowStatementAst',
			'CommandBaseAst',
			'CommandAst',
			'CommandExpressionAst',
			'ConfigurationDefinitionAst',
			'DynamicKeywordStatementAst',
			'BlockStatementAst',
			'CommandElementAst',
			'ExpressionAst',
			'ErrorExpressionAst',
			'BinaryExpressionAst',
			'UnaryExpressionAst',
			'AttributedExpressionAst',
			'ConvertExpressionAst',
			'MemberExpressionAst',
			'InvokeMemberExpressionAst',
			'BaseCtorInvokeMemberExpressionAst',
			'TypeExpressionAst',
			'VariableExpressionAst',
			'ConstantExpressionAst',
			'StringConstantExpressionAst',
			'ExpandableStringExpressionAst',
			'ScriptBlockExpressionAst',
			'ArrayLiteralAst',
			'HashtableAst',
			'ArrayExpressionAst',
			'ParenExpressionAst',
			'SubExpressionAst',
			'UsingExpressionAst',
			'IndexExpressionAst',
			'CommandParameterAst',
			'ScriptBlockAst',
			'ParamBlockAst',
			'NamedBlockAst',
			'NamedAttributeArgumentAst',
			'AttributeBaseAst',
			'AttributeAst',
			'TypeConstraintAst',
			'ParameterAst',
			'StatementBlockAst',
			'MemberAst',
			'PropertyMemberAst',
			'FunctionMemberAst',
			'CatchClauseAst',
			'RedirectionAst',
			'MergingRedirectionAst',
			'FileRedirectionAst'
		)]
		[string]$Type,

		[Parameter(Mandatory=$false)]
		[ValidateSet(
			'StatementAst',
			'PipelineBaseAst',
			'ErrorStatementAst',
			'PipelineAst',
			'AssignmentStatementAst',
			'TypeDefinitionAst',
			'UsingStatementAst',
			'FunctionDefinitionAst',
			'IfStatementAst',
			'DataStatementAst',
			'LabeledStatementAst',
			'LoopStatementAst',
			'ForEachStatementAst',
			'ForStatementAst',
			'DoWhileStatementAst',
			'DoUntilStatementAst',
			'WhileStatementAst',
			'SwitchStatementAst',
			'TryStatementAst',
			'TrapStatementAst',
			'BreakStatementAst',
			'ContinueStatementAst',
			'ReturnStatementAst',
			'ExitStatementAst',
			'ThrowStatementAst',
			'CommandBaseAst',
			'CommandAst',
			'CommandExpressionAst',
			'ConfigurationDefinitionAst',
			'DynamicKeywordStatementAst',
			'BlockStatementAst',
			'CommandElementAst',
			'ExpressionAst',
			'ErrorExpressionAst',
			'BinaryExpressionAst',
			'UnaryExpressionAst',
			'AttributedExpressionAst',
			'ConvertExpressionAst',
			'MemberExpressionAst',
			'InvokeMemberExpressionAst',
			'BaseCtorInvokeMemberExpressionAst',
			'TypeExpressionAst',
			'VariableExpressionAst',
			'ConstantExpressionAst',
			'StringConstantExpressionAst',
			'ExpandableStringExpressionAst',
			'ScriptBlockExpressionAst',
			'ArrayLiteralAst',
			'HashtableAst',
			'ArrayExpressionAst',
			'ParenExpressionAst',
			'SubExpressionAst',
			'UsingExpressionAst',
			'IndexExpressionAst',
			'CommandParameterAst',
			'ScriptBlockAst',
			'ParamBlockAst',
			'NamedBlockAst',
			'NamedAttributeArgumentAst',
			'AttributeBaseAst',
			'AttributeAst',
			'TypeConstraintAst',
			'ParameterAst',
			'StatementBlockAst',
			'MemberAst',
			'PropertyMemberAst',
			'FunctionMemberAst',
			'CatchClauseAst',
			'RedirectionAst',
			'MergingRedirectionAst',
			'FileRedirectionAst'
		)]
		[string]$ExcludeType,

		[Parameter(Mandatory=$false)]
		[switch]$Recurse = $true
	)

	begin
	{

	}

	process
	{
		if ($PSBoundParameters.ContainsKey('Type'))
		{
			$Predicate_AsString = New-Object System.Collections.Generic.List[String]
			$null = $Predicate_AsString.AddRange([string[]]@(
				"param"
				"(`$ast)"
				"process"
				"{"
			))
			if ($PSBoundParameters.ContainsKey('ExcludeType'))
			{
				$null = $Predicate_AsString.Add("if (`$ast.GetType().Name -ne `'$ExcludeType`') { if (`$ast.GetType().Name -eq `'$Type`') {`$true} else {`$false}} else {`$false}")
			}
			else
			{
				$null = $Predicate_AsString.Add("`$ast.GetType().Name -eq `'$Type`'")
			}
			$null = $Predicate_AsString.AddRange([string[]]@(
				'}'
			))

			$Predicate = [scriptblock]::Create(($Predicate_AsString -join [Environment]::NewLine))
		}
		else
		{
			$Predicate = {$true}
		}

		$Ast.FindAll($Predicate,$Recurse)
	}

	end
	{

	}

}