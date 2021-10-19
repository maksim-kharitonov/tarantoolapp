%define __distribution tarantoolapp
%define __summary "Tarantool boilerplate"

%define version %(git describe --long --tags|sed 's/-/\./g')

%define packagename %{__distribution}

%define app_dir /opt/%{__distribution}

Name:           %{__distribution}
Version:        %{version}
Release:        1%{?dist}
Summary:        %{__summary}

Group:          tarantool/db
License:        proprietary

%if %{?SRC_DIR:0}%{!?SRC_DIR:1}
Source0: %{__distribution}.tar.bz2
%endif

Requires: tarantool >= 1.10
BuildRequires: git
BuildRequires: tarantool >= 1.10
BuildRequires: lua-devel > 5.1
BuildRequires: lua-devel < 5.2
# BuildRequires: luarocks

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
%{__summary}

%if %{?SRC_DIR:1}%{!?SRC_DIR:0}
Branch: %(git rev-parse --abbrev-ref HEAD)
Commit: %(git rev-parse HEAD)
%define __git_branch %(git rev-parse --abbrev-ref HEAD)
%define __git_commit %(git rev-parse HEAD)
$ git status -suno
%(git status -suno)
%endif

%prep
pwd
%if %{?SRC_DIR:1}%{!?SRC_DIR:0}
    rm -rf %{__distribution}
    cp -ravi %{SRC_DIR} %{__distribution}
    cd %{__distribution}
%else
%setup -q -n %{__distribution}
    cd %{__distribution}
%endif

%build
pwd
cd %{__distribution}


%install
pwd
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

cd %{__distribution}

install -d -m 0755 %{buildroot}/usr/share/%{packagename}  # for init.lua, app and libs

install -m 0644 ./init.lua                  %{buildroot}/usr/share/%{packagename}/
cp -aR ./app                                %{buildroot}/usr/share/%{packagename}/
cp -aR ./libs %{buildroot}/usr/share/%{packagename}/libs

install -d -m 0755 %{buildroot}/etc/%{packagename}  # for conf.lua
install -m 0644 ./etc/conf.inst.lua         %{buildroot}/etc/%{packagename}/conf.lua

rm -rvf %{buildroot}/usr/share/%{packagename}/libs/{lib,lib64}/luarocks*

%clean
pwd
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%dir /usr/share/%{packagename}
%dir /etc/%{packagename}
/usr/share/%{packagename}/init.lua
/usr/share/%{packagename}/app
/usr/share/%{packagename}/libs

%config(noreplace) /etc/%{packagename}/conf.lua

%changelog
