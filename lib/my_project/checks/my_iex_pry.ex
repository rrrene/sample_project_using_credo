defmodule MyProject.Checks.MyIExPry do
  @moduledoc false

  @checkdoc """
  While calls to IEx.pry might appear in some parts of production code,
  most calls to this function are added during debugging sessions.

  This check warns about those calls, because they might have been committed
  in error.
  """
  @explanation [check: @checkdoc]
  @call_string "IEx.pry"

  use Credo.Check, base_priority: :high, category: :warning

  @default_params [excluded: []]
  def run(source_file, params \\ []) do
    excluded = Params.get(params, :excluded, @default_params)

    excluded_for_file? = Enum.any?(excluded, &(source_file.filename =~ &1))

    if excluded_for_file? do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)

      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    end
  end

  defp traverse(
         {
           {:., _, [{:__aliases__, _, [:IEx]}, :pry]},
           meta,
           _arguments
         } = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, issues, issue_meta) do
    new_issue =
      format_issue(
        issue_meta,
        message: "There should be no calls to IEx.pry/0.",
        trigger: @call_string,
        line_no: meta[:line]
      )

    [new_issue | issues]
  end
end