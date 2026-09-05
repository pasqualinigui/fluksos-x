// commitlint — preset mínimo inline, sem dependência de preset externo.
// Os 11 tipos são o conjunto fechado de CONTRIBUTING.md (superconjunto do
// conventional). Sem `extends`: nada para pinar além do CLI (v21.2.2 no job).
module.exports = {
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'test',
        'refactor',
        'build',
        'ci',
        'style',
        'chore',
        'perf',
        'revert',
      ],
    ],
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
  },
};
