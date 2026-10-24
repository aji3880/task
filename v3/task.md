This task list is written so all dependencies are covered in order. There might be one or two gotchas in there, but nothing should require redoing. setup user 'server' user to manage all nodes.
server1 192.168.0.69 server2 192.168.0.117
1. Lab Prep - Ignored Break into `server2` and set the password as `password`. Set the target as `multi-user`.
2. Network Connection Setup: Create a new dummy network interface connection named `dummy0` on `node1` and `node2` with `autoconnect=no` (do not modify the primary interface to prevent losing connection).
3. Service Autostart: Ensure network services (`chronyd` and `firewalld`) start automatically at boot on both servers.
4. Root SSH Access: Enable SSH access for `root` on both servers (`PermitRootLogin yes`).
5. Key-Based Authentication: Enable key-based SSH authentication for `root` on both servers.
6. Local Repository Setup: Configure the local repositories on `node1` (pointing to the HTTP repo on `node3`).
7. Copy Repo Config: Secure copy the `.repo` configuration file from `node1` to `node2`.
8. Autofs Configuration: Configure `autofs` on `node1` to automatically mount individual users' home directories from `/export/home` on `node3` (`192.168.0.217`) to `/mnt/autofs_home/<user_name>`.
9. Default File Permissions: Configure both servers to create files with `660` permissions by default (set `umask 007` in `/etc/bashrc` or `/etc/profile`).
10. Password Policies: Set password policies on both servers to require a minimum of 8 characters and a maximum age of 60 days (edit `/etc/login.defs` and `/etc/security/pwquality.conf`).
11. User Automation Script: Write shell scripts on `node1` that create users and groups according to the following parameters. Ensure all users except `cindy` use `autofs` for their home directory paths:
manny:1010:dba_admin,dba_managers,dba_staff
moe:1011:dba_admin,dba_staff
jack:1012:dba_intern,dba_staff
marcia:1013:it_staff,it_managers
jan:1014:dba_admin,dba_staff
cindy:1015:dba_intern,dba_staff
12. Deploy User Script: Secure copy the shell scripts to `node2` using `scp` and perform the same functions.
13. User Passwords: Set the password on all of the newly created users to `dbapass`.
14. Sudo Command Alias: Create a sudo command alias named `MESSAGES` with the command `/bin/tail -f /var/log/messages`.
15. Sudoers Privileges: Enable superuser privileges (`/etc/sudoers.d/`) according to the following:
     Group `dba_managers`: ALL access
     Group `dba_admin`: SOFTWARE, SERVICES, PROCESSES
     Group `dba_intern`: MESSAGES
16. Test Sudo Access: Switch to the various users using `su - <user>` and test their sudo privileges.
17. Archive /etc Directory: On `node1`, create a `tar` w/ `gzip` archive of `/etc` called `etc_archive.tar.gz` in the `/archives` directory.
18. Archive /usr/share/doc Directory: On `node1`, create a `tar` w/ `bzip2` archive of `/usr/share/doc` called `doc_archive.tar.bz2` in the `/archives` directory.
19. Soft and Hard Links: On `node1`, create a folder called `/links`. Inside `/links`, create a file called `file01`. Create a soft link called `file02` pointing to `file01`, and a hard link called `file03` pointing to `file01`.
20. Find SUID Files: Find all setuid (SUID) files on `node1` and save the list to `/root/suid.txt`.
21. Find Large Files: Find all files larger than 3MB in the `/etc` directory on `node1` and copy them to `/largefiles`.
22. NFS Mount DBA Files: On both servers, persistently mount `/export/dba_files` from `node3` (`192.168.0.217`) under `/mnt/dba_files`. Ensure `manny` is the user owner and `dba_staff` is the group owner. Apply the SGID bit on the directory, enable the sticky bit, and restrict directory access to members of the `dba_staff` group only.
23. NFS Mount IT Files: On both servers, persistently mount `/export/it_files` from `node3` (`192.168.0.217`) under `/mnt/it_files`. Ensure `marcia` is the user owner and `it_staff` is the group owner. Apply the SGID bit on the directory, enable the sticky bit, and restrict directory access to members of the `it_staff` group only.
24. At Scheduler Job: Create a job using `at` to write `"This task was easy!"` to `/coolfiles/at_job.txt` in 10 minutes.
25. Cron Scheduler Job: Create a job using `cron` to write `"Wow! I'm going to pass this test!"` every Tuesday at 3pm to `/var/log/messages`.
26. Shell Script Logic: Write a script named `awesome.sh` in the `/root` directory on `node1`:
     If `"me"` is given as an argument, output: `"Yes, I’m awesome."`
     If `"them"` is given as an argument, output: `"Okay, they are awesome."`
     If the argument is empty or anything else, output: `"Usage ./awesome.sh me|them"`
27. Troubleshoot Web Server: Fix the web server (`httpd`) on `node1` (port 85 & SELinux context) and ensure all files are accessible without modifying the main `httpd` configuration files. Ensure it is accessible from `node2` and client browser.
28. SELinux Permissive Mode: Put SELinux on `node2` in `Permissive` mode both temporarily and permanently (`/etc/selinux/config`).
29. Systemd Boot Target: On `node1`, set the default systemd target to `multi-user.target` and verify the active target.
30. NTP Synchronization: Configure NTP synchronization on both servers using `chrony`, pointing them to the local NTP server or lab gateway (`192.168.0.1` or `node3` IP).
31. Persistent Journaling: Configure persistent journaling for `systemd-journald` on both servers (create `/var/log/journal`).
32. LVM Volume Group Creation: On `node2`, create a new 2GiB volume group named `platforms_vg` on `/dev/loop10` (or available secondary disk).
33. Logical Volume Creation: Under the `platforms_vg` volume group, create a 500MiB logical volume named `platforms_lv` and format it as `ext4`.
34. Persistent Mount: Mount it persistently (`/etc/fstab`) under `/mnt/platforms_lv`.
35. LVM Extension: Extend the `platforms_lv` logical volume and filesystem by 500MiB (totaling 1GiB).
36. Swap Partition: On `node2`, create a 500MiB swap partition on `/dev/loop10` and enable it persistently in `/etc/fstab`.
37. LVM Networks VG: On `node2`, using the remaining space on `/dev/loop10`, create a volume group named `networks_vg`.
38. LVM Extent Sizing: Under the `networks_vg` volume group, create a logical volume named `networks_lv`. Ensure it uses 8MiB extents and configure it to use 75 extents. Format it with the `vfat` filesystem and mount it persistently on `/mnt/networks_lv`.
39. LVM Thin Provisioning: On `node2`, create a 5TB thin-provisioned volume named `thin_vol` backed by a pool called `thin_pool` on a 5GB volume group called `thin_vg` using `/dev/loop11`. Format it as `xfs` and mount it persistently under `/mnt/thin_vol`.
40. Tuned Profile Setup: On `node1`, set a merged `tuned` profile using the `powersave` and `virtual-guest` profiles.
41. Process Niceness: On `node1`, start one `stress-ng` (or `stress`) process with a niceness value of 19. Adjust the niceness value of the running stress process to 10, then kill the process.
42. Container Image Build: On `node1`, as the user `cindy`, create a container image from `http://192.168.0.217/Containerfile` (or local Containerfile) with the tag `web_image` using `podman`.
43. Rootless Container Service: From the newly created image, deploy a rootless container service with the container name `cindy_web`. Map the web files directory to `~/web_files`, and map local port `8000` to container port `80`. Create a default index page saying `"Welcome to Cindy's Web Server!"`. Ensure the systemd user service is enabled and the website is accessible.