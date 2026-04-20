
2024-07-19 11:54

Status:

Tags: [[git]] [[command]]


# Git command

## rename a  branch
1. checkout the local branch that you want to rename: `git checkout old-branch-name`
2. rename it: `git branch -m new-branch-name`
3. push the new branch and reset the upstream branch for the new branch `git push origin -u new-branch-name`
4. delete the old branch from the remote: `git push origin --delete old-branch-name`
5. clean up local references, if other coworkers have checked out the old branch, they can clean up their local references with: `git fetch -p`
## delete a local branch
1.  When we need to delete a local branch which does not have remote branch: 
	1. we need to checkout another branch, because you cannot delete a branch you are currently on. `git checkout main`
	2. use `-d` flag to delete the branch, this will delete the branch only if it has been fully merged:`git branch -d branch-name`
	3. Use the `-D` flag to force delete the branch, regardless of its merge status: `git branch -D branch-name`




# References