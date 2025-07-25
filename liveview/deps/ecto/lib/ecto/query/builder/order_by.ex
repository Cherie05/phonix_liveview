import Kernel, except: [apply: 3]

defmodule Ecto.Query.Builder.OrderBy do
  @moduledoc false

  alias Ecto.Query.Builder

  @directions [
    :asc,
    :asc_nulls_last,
    :asc_nulls_first,
    :desc,
    :desc_nulls_last,
    :desc_nulls_first
  ]

  @doc """
  Returns `true` if term is a valid order_by direction; otherwise returns `false`.

  ## Examples

      iex> valid_direction?(:asc)
      true

      iex> valid_direction?(:desc)
      true

      iex> valid_direction?(:invalid)
      false

  """
  def valid_direction?(term), do: term in @directions

  @doc """
  Escapes an order by query.

  The query is escaped to a list of `{direction, expression}`
  pairs at runtime. Escaping also validates direction is one of
  `:asc`, `:asc_nulls_last`, `:asc_nulls_first`, `:desc`,
  `:desc_nulls_last` or `:desc_nulls_first`.

  ## Examples

      iex> escape(:order_by, quote do [x.x, desc: 13] end, {[], %{}}, [x: 0], __ENV__)
      {[asc: {:{}, [], [{:{}, [], [:., [], [{:{}, [], [:&, [], [0]]}, :x]]}, [], []]},
        desc: 13],
       {[], %{}}}

  """
  @spec escape(:order_by | :distinct, Macro.t(), {list, term}, Keyword.t(), Macro.Env.t()) ::
          {Macro.t(), {list, term}}
  def escape(kind, expr, params_acc, vars, env) do
    expr
    |> List.wrap()
    |> Enum.flat_map_reduce(params_acc, &do_escape(&1, &2, kind, vars, env))
  end

  defp do_escape({dir, {:^, _, [expr]}}, params_acc, kind, _vars, _env) do
    {[{quoted_dir!(kind, dir),
      quote(do: Ecto.Query.Builder.OrderBy.field!(unquote(kind), unquote(expr)))}], params_acc}
  end

  defp do_escape({:^, _, [expr]}, params_acc, kind, _vars, _env) do
    {[{:asc, quote(do: Ecto.Query.Builder.OrderBy.field!(unquote(kind), unquote(expr)))}],
     params_acc}
  end

  defp do_escape({dir, field}, params_acc, kind, _vars, _env) when is_atom(field) do
    {[{quoted_dir!(kind, dir), Macro.escape(to_field(field))}], params_acc}
  end

  defp do_escape(field, params_acc, _kind, _vars, _env) when is_atom(field) do
    {[{:asc, Macro.escape(to_field(field))}], params_acc}
  end

  defp do_escape({dir, expr}, params_acc, kind, vars, env) do
    fun = &escape_expansion(kind, &1, &2, &3, &4, &5)
    {ast, params_acc} = Builder.escape(expr, :any, params_acc, vars, {get_env(env), fun})
    {[{quoted_dir!(kind, dir), ast}], params_acc}
  end

  defp do_escape(expr, params_acc, kind, vars, env) do
    fun = &escape_expansion(kind, &1, &2, &3, &4, &5)
    {ast, params_acc} = Builder.escape(expr, :any, params_acc, vars, {get_env(env), fun})

    if is_list(ast) do
      {ast, params_acc}
    else
      {[{:asc, ast}], params_acc}
    end
  end

  defp get_env({env, _}), do: env
  defp get_env(env), do: env

  defp escape_expansion(kind, expr, _type, params_acc, vars, env) when is_list(expr) do
    escape(kind, expr, params_acc, vars, env)
  end

  defp escape_expansion(_kind, field, _type, params_acc, _vars, _env) when is_atom(field) do
    {Macro.escape(to_field(field)), params_acc}
  end

  defp escape_expansion(kind, expr, type, params_acc, vars, env) do
    fun = &escape_expansion(kind, &1, &2, &3, &4, &5)
    Builder.escape(expr, type, params_acc, vars, {env, fun})
  end

  @doc """
  Checks the variable is a quoted direction at compilation time or
  delegate the check to runtime for interpolation.
  """
  def quoted_dir!(kind, {:^, _, [expr]}),
    do: quote(do: Ecto.Query.Builder.OrderBy.dir!(unquote(kind), unquote(expr)))

  def quoted_dir!(_kind, dir) when dir in @directions,
    do: dir

  def quoted_dir!(kind, other) do
    Builder.error!(
      "expected #{Enum.map_join(@directions, ", ", &inspect/1)} or interpolated value " <>
        "in `#{kind}`, got: `#{inspect(other)}`"
    )
  end

  @doc """
  Called at runtime to verify the direction.
  """
  def dir!(_kind, dir) when dir in @directions,
    do: dir

  def dir!(kind, other) do
    raise ArgumentError,
          "expected one of #{Enum.map_join(@directions, ", ", &inspect/1)} " <>
            "in `#{kind}`, got: `#{inspect(other)}`"
  end

  @doc """
  Called at runtime to verify a field.
  """
  def field!(_kind, field) when is_atom(field) do
    to_field(field)
  end

  def field!(kind, %Ecto.Query.DynamicExpr{} = dynamic_expression) do
    raise ArgumentError,
          "expected a field as an atom in `#{kind}`, got: `#{inspect(dynamic_expression)}`. " <>
            "To use dynamic expressions, you need to interpolate at root level, as in: " <>
            "`^[asc: dynamic, desc: :id]`"
  end

  def field!(kind, other) do
    raise ArgumentError, "expected a field as an atom in `#{kind}`, got: `#{inspect(other)}`"
  end

  defp to_field(field), do: {{:., [], [{:&, [], [0]}, field]}, [], []}

  @doc """
  Shared between order_by and distinct.
  """
  def order_by_or_distinct!(kind, query, exprs, params) do
    {expr, {params, _, subqueries}} =
      Enum.map_reduce(List.wrap(exprs), {params, length(params), []}, fn
        {dir, expr}, params_count when dir in @directions ->
          {expr, params} = dynamic_or_field!(kind, expr, query, params_count)
          {{dir, expr}, params}

        expr, params_count ->
          {expr, params} = dynamic_or_field!(kind, expr, query, params_count)
          {{:asc, expr}, params}
      end)

    {expr, params, subqueries}
  end

  @doc """
  Called at runtime to assemble order_by.
  """
  def order_by!(query, exprs, op, file, line) do
    {expr, params, subqueries} = order_by_or_distinct!(:order_by, query, exprs, [])

    expr = %Ecto.Query.ByExpr{
      expr: expr,
      params: Enum.reverse(params),
      line: line,
      file: file,
      subqueries: subqueries
    }

    apply(query, expr, op)
  end

  defp dynamic_or_field!(
         _kind,
         %Ecto.Query.DynamicExpr{} = dynamic,
         query,
         {params, count, subqueries}
       ) do
    {expr, params, subqueries, _aliases, count} =
      Ecto.Query.Builder.Dynamic.partially_expand(
        query,
        dynamic,
        params,
        subqueries,
        %{},
        count
      )

    {expr, {params, count, subqueries}}
  end

  defp dynamic_or_field!(_kind, field, _query, params_count) when is_atom(field) do
    {to_field(field), params_count}
  end

  defp dynamic_or_field!(kind, other, _query, _params_count) do
    raise ArgumentError,
          "`#{kind}` interpolated on root expects a field or a keyword list " <>
            "with the direction as keys and fields or dynamics as values, got: `#{inspect(other)}`"
  end

  @doc """
  Builds a quoted expression.

  The quoted expression should evaluate to a query at runtime.
  If possible, it does all calculations at compile time to avoid
  runtime work.
  """
  @spec build(Macro.t(), [Macro.t()], Macro.t(), :append | :prepend, Macro.Env.t()) :: Macro.t()
  def build(query, _binding, {:^, _, [var]}, op, env) do
    quote do
      Ecto.Query.Builder.OrderBy.order_by!(
        unquote(query),
        unquote(var),
        unquote(op),
        unquote(env.file),
        unquote(env.line)
      )
    end
  end

  def build(query, binding, expr, op, env) do
    {query, binding} = Builder.escape_binding(query, binding, env)
    {expr, {params, acc}} = escape(:order_by, expr, {[], %{subqueries: []}}, binding, env)
    params = Builder.escape_params(params)

    order_by =
      quote do: %Ecto.Query.ByExpr{
              expr: unquote(expr),
              params: unquote(params),
              subqueries: unquote(acc.subqueries),
              file: unquote(env.file),
              line: unquote(env.line)
            }

    Builder.apply_query(query, __MODULE__, [order_by, op], env)
  end

  @doc """
  The callback applied by `build/4` to build the query.
  """
  @spec apply(Ecto.Queryable.t(), term, term) :: Ecto.Query.t()
  def apply(%Ecto.Query{order_bys: orders} = query, expr, op) do
    %{query | order_bys: update_order_bys(orders, expr, op)}
  end

  def apply(query, expr, op) do
    apply(Ecto.Queryable.to_query(query), expr, op)
  end

  @doc """
  Updates the `order_bys` value for a query.
  """
  def update_order_bys(orders, expr, :append), do: orders ++ [expr]
  def update_order_bys(orders, expr, :prepend), do: [expr | orders]

  def update_order_bys(orders, expr, mode) do
    quote do
      Ecto.Query.Builder.OrderBy.update_order_bys(unquote(orders), unquote(expr), unquote(mode))
    end
  end
end
