---
---

Please do these checks in PR and delete it from PR message:

# CVS checklist
- [ ] Each commit does only one change at time, and it is expressed clearly in
      the commit message.
- [ ] The commit message includes reference to github & Youtrack issue number

# Code checklist
- [ ] Use `declare <varname>` with the variables, to make them local (check
      bash `declare --help`). Use `declare -g` if you need them global. Feel
      free if you need to declare them read-only (`-r`) or integers (`-i`).
- [ ] The code does NOT contain comments that can be omitted, especially
      comments that you can avoid creating another function.
- [ ] Validate all user inputs, fail loudly if not used properly.
- [ ] Check All return codes.
- [ ] Document all modified functions and files:
  - Function/file arguments (make clear which ones will be used as output too).
  - Environment
  - Standard and stderr output
  - Exit status
- [ ] Update changes related documentation & user messages in the same commit
      as changes occur (`README.md` and `docs/` subfolder), and user information
      messages.
- [ ] New helper functions are justified by the fact that there is no other
      function I can use/extend for my case. If I extend one, I've checked all
      the uses, and I've tried to stick to old API.
- [ ] Update tests cases, especially looking for corner cases and errors path.
      Code coverage should show that tests passed by the code I modified.
- [ ] New libraries/components have a test to show when they are outdated.
- [ ] Changes are reflected in `update_internal.bash` if needed.

# Use of tools
- [ ] Check text changes against these tools:
  - [ ] Grammarly or similar (if available)
