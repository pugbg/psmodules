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
		[string]$Type
	)

	begin
	{

	}

	process
	{
		if ($PSBoundParameters.ContainsKey('Type'))
		{
			$Predicate = [scriptblock]::Create(@"
				param
				(`$ast)

				process
				{
					`$ast.GetType().Name -eq `'$Type`'
				}
"@)
		}
		else
		{
			$Predicate = {$true}
		}

		$Ast.FindAll($Predicate,$true)
	}

	end
	{

	}

}