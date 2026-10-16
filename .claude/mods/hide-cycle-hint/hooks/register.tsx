import type { Register } from 'claude-code'

const CYCLE = /\s*\(shift\+tab to cycle\)/gi
const DANGLING = /^[\s·•・]+|[\s·•・]+$/g

export const register: Register = on => {
  on('ui.render', { component: 'PromptHint' }, ($, e, next) => {
    const hint = e.props.hint.replace(CYCLE, '').replace(DANGLING, '')

    if (hint === e.props.hint) {
      return next(e)
    }

    return next({ ...e, props: { ...e.props, hint } })
  })
}
