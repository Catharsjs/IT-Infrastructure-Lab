# File-server evidence

Five screenshots supplied by the lab owner and approved for public project documentation. Captures show **2026-08-31, approximately 17:30–17:34 lab time**.

| File | Evidence |
|---|---|
| [share-inventory.png](share-inventory.png) | FS01 shares and local folder paths |
| [smb-read-permissions.png](smb-read-permissions.png) | IT-Developers share: R group selected, Allow Read |
| [smb-change-permissions.png](smb-change-permissions.png) | IT-Developers share: M group selected, Allow Change and Read |
| [ntfs-developers.png](ntfs-developers.png) | Developers folder owner, explicit NTFS entries, and inheritance state |
| [client-access.png](client-access.png) | Explorer listing the share alongside whoami output in the client session |

Images are copied unchanged. They show lab host/domain/group names, folder paths, a Windows user name, a test-file name, and surrounding UI context. No visible passwords or private keys are included. The client capture includes a domain GUID in earlier diagnostic output; it is an identifier, not an authentication secret.

The screenshots are read-only observations, not evidence that new permission changes were made during capture. See [File Server and SMB access](../../docs/file-server.md) for the exact scope of each observation.
