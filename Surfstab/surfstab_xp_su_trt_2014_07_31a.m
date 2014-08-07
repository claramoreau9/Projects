% Here are the things we want to do
% 1) Average contrast map
% 2) Similarity measure of some of the maps
% 3) Hierarchical clustering of the similarity map to find subject groups
%% Clear
clear;
%% Define the input data
in_path = '/home/surchs/Projects/stability_abstract/full_run/data/sc10/stability_maps';
% Search for the files we need and build the structure
f = dir(in_path);
in_strings = {f.name};
in_files = {};
f_count = 1;
for f_id = 1:numel(in_strings)
    in_string = in_strings{f_id};
    % Get anything with a nii.gz in the end
    [start, stop] = regexp(in_string, '\w*.nii.gz');
    if ~isempty(start) && ~isempty(stop)
        sub_name = in_string(start:stop);
        in_files{f_count} = [in_path filesep in_string];
        f_count = f_count + 1;
    end
end

%% Average the contrast map
for f_id = 1:numel(in_files)
    [t_hdr, t_vol] = niak_read_vol(in_files{f_id});
    if f_id == 1
        avg_contrast = t_vol;
    else
        avg_contrast = avg_contrast + t_vol;
    end
end
%% Build the distance map
num_n = 10;
for n_id = 1:num_n
    
    files_map = [];
    for f_id = 1:numel(in_files)
        [h_in, v_in] = niak_read_vol(in_files{f_id});
        use = v_in(:,:,:,n_id);
        vec_in = use(:);
        if f_id == 1
            files_map = vec_in;
        else
            files_map = [files_map, vec_in];
        end
    end

    vopt.color_map = niak_hot_cold();
    S = niak_build_correlation(files_map);
    D = niak_build_distance(files_map);
    hier = niak_hierarchical_clustering(S);
    hier_d = niak_hierarchical_clustering(-D);
    opt.thresh = 25;
    part = niak_threshold_hierarchy(hier, opt);
    d_part = niak_threshold_hierarchy(hier_d, opt);
    % Make a partition matrix
    tmat = niak_part2mat(part);
    dmat = niak_part2mat(d_part);
    
    clf;
    subplot(2,2,1), niak_visu_matrix(S, vopt);
    subplot(2,2,2), niak_visu_matrix(D, vopt);
    subplot(2,2,3), niak_visu_matrix(tmat);
    subplot(2,2,4), niak_visu_matrix(dmat);
    title(sprintf('Network %d at scale 10', n_id));
    
    print(gcf, '-dpng', sprintf('plot_network_%d.png', n_id));
end

